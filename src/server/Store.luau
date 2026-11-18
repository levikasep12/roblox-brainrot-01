-- Store: the one place server state lives. Every module reads and writes
-- profiles through here, so there is exactly one source of truth for money,
-- rebirths, base slots, locks, cooldowns and the income multiplier. The store
-- also owns the profile -> client serialisation, keeping the wire shape in one
-- file instead of scattered across remotes.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Store = {}

-- Server-wide monotonic-ish wall clock. now() is CPU time, which can fall
-- behind wall time on an idle server and stretch every timer (waves, locks, x2).
local function now(): number
	return workspace:GetServerTimeNow()
end

local profiles: { [Player]: any } = {}
local plotOwners: { [number]: Player? } = {}

local function blankProfile(plotIndex: number)
	return {
		money = Config.StartingMoney,
		rebirths = 0,
		slots = {}, -- [slotIndex] = { defId, mutation, rate, earned }
		lockUntil = 0,
		stealReadyAt = 0,
		x2Until = 0,
		plotIndex = plotIndex,
		earnedTotal = 0,
		steals = 0,
	}
end

local function firstFreePlot(): number?
	for index = 1, Config.PlotCount do
		if not plotOwners[index] then
			return index
		end
	end
	return nil
end

function Store.get(player: Player)
	return profiles[player]
end

function Store.all()
	return profiles
end

function Store.plotOwner(plotIndex: number): Player?
	return plotOwners[plotIndex]
end

function Store.plotOwnerOf(player: Player): number?
	local profile = profiles[player]
	return profile and profile.plotIndex or nil
end

function Store.load(player: Player): boolean
	if profiles[player] then
		return true
	end
	local index = firstFreePlot()
	if not index then
		return false
	end
	plotOwners[index] = player
	profiles[player] = blankProfile(index)
	return true
end

function Store.unload(player: Player)
	local profile = profiles[player]
	if profile then
		plotOwners[profile.plotIndex] = nil
	end
	profiles[player] = nil
end

function Store.income(player: Player): number
	local profile = profiles[player]
	if not profile then
		return 0
	end
	local base = 0
	for _, slot in pairs(profile.slots) do
		base += slot.rate
	end
	return base * Config.rebirthMultiplier(profile.rebirths)
end

function Store.incomeMultiplier(player: Player): number
	local profile = profiles[player]
	if not profile then
		return 1
	end
	local multiplier = Config.rebirthMultiplier(profile.rebirths)
	if now() < profile.x2Until then
		multiplier *= 2
	end
	return multiplier
end

function Store.addMoney(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.money += amount
	if amount > 0 then
		profile.earnedTotal += amount
	end
end

function Store.trySpend(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile or profile.money < amount then
		return false
	end
	profile.money -= amount
	return true
end

--- The compact table the HUD renders. Deliberately flat: the client never
--- reaches into server objects, it just draws this.
function Store.snapshot(player: Player)
	local profile = profiles[player]
	if not profile then
		return nil
	end
	local slots = {}
	for index = 1, Config.MaxSlots do
		local slot = profile.slots[index]
		if slot then
			slots[index] = {
				defId = slot.defId,
				mutation = slot.mutation,
				rate = slot.rate,
			}
		end
	end
	return {
		money = math.floor(profile.money),
		rebirths = profile.rebirths,
		multiplier = Config.rebirthMultiplier(profile.rebirths),
		income = Store.income(player),
		x2 = now() < profile.x2Until,
		x2Left = math.max(0, profile.x2Until - now()),
		lockLeft = math.max(0, profile.lockUntil - now()),
		plotIndex = profile.plotIndex,
		slots = slots,
		steals = profile.steals,
		rebirthCost = Config.rebirthCost(profile.rebirths),
		lockCost = Config.LockCost,
	}
end

return Store
