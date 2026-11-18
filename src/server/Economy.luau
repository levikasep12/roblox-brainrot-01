-- Economy: the money rules. It spends and credits money through the Store,
-- moves a bought brainrot from the conveyor onto the buyer's next free slot,
-- ticks passive income, and handles rebirths and base-lock purchases. Any
-- player-facing failure comes back as a (false, reason) pair so callers can
-- show the reason without duplicating validation.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Economy = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local Store
local Conveyor
local Bases
local Net
local Roster

function Economy.init(deps: any)
	Store = deps.store
	Conveyor = deps.conveyor
	Bases = deps.bases
	Net = deps.net
	Roster = deps.roster
end

function Economy.notify(player: Player, message: string)
	local remote = Net.get("Notice")
	if remote then
		remote:FireClient(player, message)
	end
end

local function freeSlot(player: Player): number?
	local profile = Store.get(player)
	if not profile then
		return nil
	end
	for slotIndex = 1, Config.MaxSlots do
		if not profile.slots[slotIndex] then
			return slotIndex
		end
	end
	return nil
end

--- Places an owned brainrot into a free slot and redraws the plot.
local function install(player: Player, defId: string, mutationId: string, rate: number): boolean
	local profile = Store.get(player)
	if not profile then
		return false
	end
	local slotIndex = freeSlot(player)
	if not slotIndex then
		return false
	end
	profile.slots[slotIndex] = { defId = defId, mutation = mutationId, rate = rate }
	Bases.setSlot(profile.plotIndex, slotIndex, defId, mutationId, player.DisplayName)
	return true
end

function Economy.buyConveyorItem(player: Player, item: any)
	local profile = Store.get(player)
	if not profile then
		return false, "No profile loaded."
	end
	if not freeSlot(player) then
		return false, "Your base is full. Rebirth or steal a slot-free upgrade."
	end
	if not Store.trySpend(player, item.price) then
		return false, ("Need $%d, you have $%d."):format(item.price, math.floor(profile.money))
	end
	if not install(player, item.def.id, item.mutation.id, math.floor(item.def.rate * item.mutation.rateMultiplier)) then
		Store.addMoney(player, item.price)
		return false, "Your base is full."
	end
	local remote = Net.get("EffectBurst")
	if remote then
		remote:FireClient(player, "buy", item.def.name)
	end
	Roster.broadcast()
	return true, ("Bought %s!"):format(item.def.name)
end

--- Grants a brainrot won by stealing (already validated by Steal).
function Economy.grant(player: Player, defId: string, mutationId: string, rate: number): boolean
	local ok = install(player, defId, mutationId, rate)
	Roster.broadcast()
	return ok
end

function Economy.hasRoom(player: Player): boolean
	return freeSlot(player) ~= nil
end

function Economy.buyLock(player: Player)
	local profile = Store.get(player)
	if not profile then
		return false, "No profile loaded."
	end
	if now() < profile.lockUntil then
		return false, "Your base is already locked."
	end
	if not Store.trySpend(player, Config.LockCost) then
		return false, ("A lock costs $%d."):format(Config.LockCost)
	end
	profile.lockUntil = now() + Config.LockDuration
	Bases.setLocked(profile.plotIndex, true)
	Roster.broadcast()
	return true, "Base locked for 60s."
end

function Economy.rebirth(player: Player)
	local profile = Store.get(player)
	if not profile then
		return false, "No profile loaded."
	end
	local cost = Config.rebirthCost(profile.rebirths)
	if profile.money < cost then
		return false, ("Rebirth costs $%d."):format(cost)
	end
	profile.money = Config.StartingMoney
	profile.rebirths += 1
	table.clear(profile.slots)
	Bases.renderPlot(profile.plotIndex, profile.slots, player.DisplayName)
	Roster.broadcast()
	return true, ("Rebirth %d! Income x%.2f"):format(profile.rebirths, Config.rebirthMultiplier(profile.rebirths))
end

--- Passive income. One loop for everyone: income * dt, with the wave x2 bonus
--- and rebirth multiplier already folded in by Store.
function Economy.start()
	local RunService = game:GetService("RunService")
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < 0.1 then
			return
		end
		local step = accumulator
		accumulator = 0
		for player, profile in pairs(Store.all()) do
			local base = 0
			for _, slot in pairs(profile.slots) do
				base += slot.rate
			end
			if base > 0 then
				local multiplier = Config.rebirthMultiplier(profile.rebirths)
				if now() < profile.x2Until then
					multiplier *= 2
				end
				profile.money += base * multiplier * step
				profile.earnedTotal += base * multiplier * step
			end
			if profile.lockUntil > 0 and now() >= profile.lockUntil then
				profile.lockUntil = 0
				Bases.setLocked(profile.plotIndex, false)
			end
		end
	end)
end

return Economy
