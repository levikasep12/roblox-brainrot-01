-- Steal: the threat half of the loop. A player near a rival's base can take one
-- brainrot from it, unless that base is locked or the thief is on cooldown.
-- The stolen brainrot moves to the thief's base if there is room; otherwise the
-- thief simply banks a salvage payout. Validation lives here, once, so the
-- client can only ever request a steal, never invent one.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotDefs = require(game:GetService("ReplicatedStorage").Shared.BrainrotDefs)

local Steal = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local Store
local Bases
local Economy
local Net
local Roster

function Steal.init(deps: any)
	Store = deps.store
	Bases = deps.bases
	Economy = deps.economy
	Net = deps.net
	Roster = deps.roster
end

--- Finds the nearest rival plot to a character, and the richest brainrot on it.
local function nearestRivalPlot(player: Player): (number?, Vector3?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil, nil
	end
	local ownPlot = Store.plotOwnerOf(player)
	local bestPlot, bestDistance = nil, math.huge
	for plotIndex = 1, Config.PlotCount do
		if plotIndex ~= ownPlot and Store.plotOwner(plotIndex) then
			local centre = Bases.plotCentre(plotIndex)
			if centre then
				local distance = (hrp.Position - centre).Magnitude
				if distance < bestDistance then
					bestPlot, bestDistance = plotIndex, distance
				end
			end
		end
	end
	if bestPlot and bestDistance <= Config.BaseRadius + 6 then
		return bestPlot, hrp.Position
	end
	return nil, nil
end

local function bestSlot(profile: any): (number?, any)
	local bestIndex, bestRate = nil, -1
	for slotIndex, slot in pairs(profile.slots) do
		if slot.rate > bestRate then
			bestIndex, bestRate = slotIndex, slot.rate
		end
	end
	return bestIndex, bestRate >= 0 and profile.slots[bestIndex or 0] or nil
end

function Steal.attempt(thief: Player)
	local thiefProfile = Store.get(thief)
	if not thiefProfile then
		return false, "No profile loaded."
	end
	local now = now()
	if now < thiefProfile.stealReadyAt then
		return false, ("Steal cooling down (%.0fs)."):format(thiefProfile.stealReadyAt - now)
	end

	local plotIndex = nearestRivalPlot(thief)
	if not plotIndex then
		return false, "Stand inside a rival's base to steal."
	end

	local victim = Store.plotOwner(plotIndex)
	if not victim then
		return false, "That base is empty."
	end
	local victimProfile = Store.get(victim)
	if not victimProfile then
		return false, "That base is empty."
	end
	if now < victimProfile.lockUntil then
		return false, ("%s's base is locked (%.0fs)."):format(victim.DisplayName, victimProfile.lockUntil - now)
	end

	local slotIndex, slot = bestSlot(victimProfile)
	if not slotIndex or not slot then
		return false, "Nothing to steal there yet."
	end

	victimProfile.slots[slotIndex] = nil
	Bases.clearSlot(plotIndex, slotIndex)
	thiefProfile.stealReadyAt = now + Config.StealCooldown
	thiefProfile.steals += 1

	local def = BrainrotDefs.get(slot.defId)
	local moved = Economy.grant(thief, slot.defId, slot.mutation, slot.rate)
	if not moved then
		local salvage = math.floor((def and def.price or 50) * 0.5)
		Store.addMoney(thief, salvage)
		Economy.notify(thief, ("Base full: salvaged %s for $%d."):format(def and def.name or "brainrot", salvage))
	else
		Economy.notify(thief, ("Stole %s from %s!"):format(def and def.name or "a brainrot", victim.DisplayName))
	end
	Economy.notify(victim, ("%s stole your %s! Buy a lock."):format(thief.DisplayName, def and def.name or "brainrot"))

	local burst = Net.get("EffectBurst")
	if burst then
		burst:FireClient(thief, "steal", def and def.name or "brainrot")
		burst:FireClient(victim, "stolen", def and def.name or "brainrot")
	end
	Roster.broadcast()
	return true, "Steal successful."
end

return Steal
