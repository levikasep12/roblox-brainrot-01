-- The one place all server state lives: player profiles, the belt, rival
-- bases and the hazard wave. Other server modules read and mutate through here.

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local BrainrotDefs = require(game:GetService("ReplicatedStorage").Shared.BrainrotDefs)
local PlotLayout = require(game:GetService("ReplicatedStorage").Shared.PlotLayout)

local Store = {}

Store.state = {
	players = {},
	rivals = {},
	belt = {},
	nextBeltId = 1,
	hazard = {
		phase = "idle",
		waveIndex = 0,
		z = GameConfig.Hazard.startZ,
		startedAt = 0,
		endsAt = 0,
		nextAt = os.clock() + GameConfig.Hazard.firstDelay,
	},
}

function Store.newProfile(userId: number, name: string)
	local profile = {
		userId = userId,
		name = name,
		money = GameConfig.StartingMoney,
		rebirths = 0,
		multiplier = 1,
		plotIndex = 0,
		slots = {},
		lockUntil = 0,
		stealCooldownUntil = 0,
		dashUntil = 0,
		dashCooldownUntil = 0,
		lastWaveHit = 0,
		stats = { earned = 0, spent = 0, steals = 0, stolen = 0, rebirths = 0 },
		joinedAt = os.clock(),
	}
	return profile
end

function Store.getPlayer(userId: number)
	return Store.state.players[userId]
end

function Store.allPlayers(): { any }
	local list = {}
	for _, profile in pairs(Store.state.players) do
		table.insert(list, profile)
	end
	table.sort(list, function(a, b)
		return a.joinedAt < b.joinedAt
	end)
	return list
end

function Store.claimFreePlot(): number
	local taken = {}
	for _, profile in pairs(Store.state.players) do
		taken[profile.plotIndex] = true
	end
	for _, plotIndex in ipairs(PlotLayout.PlayerPlotIndexes) do
		if not taken[plotIndex] then
			return plotIndex
		end
	end
	return 0
end

function Store.freeSlotIndex(profile): number
	if profile.plotIndex == 0 then
		return 0
	end
	for slot = 1, GameConfig.StartingSlots do
		if not profile.slots[slot] then
			return slot
		end
	end
	return 0
end

function Store.addMoney(profile, amount: number)
	profile.money += amount
	profile.stats.earned += math.max(0, amount)
end

function Store.spendMoney(profile, amount: number): boolean
	if profile.money < amount then
		return false
	end
	profile.money -= amount
	profile.stats.spent += amount
	return true
end

function Store.placeSlot(profile, slotIndex: number, defId: string, mutationId: string)
	local def = BrainrotDefs.get(defId)
	if not def then
		return nil
	end
	local record = {
		defId = defId,
		mutationId = mutationId,
		rate = BrainrotDefs.rateFor(def, mutationId),
		placedAt = os.clock(),
	}
	profile.slots[slotIndex] = record
	return record
end

function Store.removeSlot(profile, slotIndex: number)
	local record = profile.slots[slotIndex]
	profile.slots[slotIndex] = nil
	return record
end

function Store.slotCount(profile): number
	local count = 0
	for slot = 1, GameConfig.StartingSlots do
		if profile.slots[slot] then
			count += 1
		end
	end
	return count
end

function Store.baseIncome(profile): number
	local total = 0
	for slot = 1, GameConfig.StartingSlots do
		local record = profile.slots[slot]
		if record then
			total += record.rate
		end
	end
	return total * profile.multiplier
end

function Store.hasLock(profile): boolean
	return profile.lockUntil > os.clock()
end

function Store.newRival(plotIndex: number, name: string)
	return {
		plotIndex = plotIndex,
		name = name,
		slots = {},
		nextRestock = os.clock() + math.random(6, GameConfig.Rival.restockInterval),
	}
end

function Store.newBeltEntry(defId: string, mutationId: string)
	local entry = {
		id = Store.state.nextBeltId,
		defId = defId,
		mutationId = mutationId,
		x = GameConfig.Conveyor.startX,
		claimed = false,
	}
	Store.state.nextBeltId += 1
	table.insert(Store.state.belt, entry)
	return entry
end

function Store.removeBeltEntry(entryId: number)
	for index, entry in ipairs(Store.state.belt) do
		if entry.id == entryId then
			table.remove(Store.state.belt, index)
			return entry
		end
	end
	return nil
end

function Store.beltEntries(): { any }
	return Store.state.belt
end

function Store.toSnapshot(profile)
	local slots = {}
	for slot = 1, GameConfig.StartingSlots do
		local record = profile.slots[slot]
		slots[slot] = if record
			then { defId = record.defId, mutationId = record.mutationId, rate = record.rate }
			else nil
	end
	return {
		money = profile.money,
		multiplier = profile.multiplier,
		rebirths = profile.rebirths,
		plotIndex = profile.plotIndex,
		slots = slots,
		income = Store.baseIncome(profile),
		lockRemaining = math.max(0, profile.lockUntil - os.clock()),
		stealReady = math.max(0, profile.stealCooldownUntil - os.clock()),
		dashReady = math.max(0, profile.dashCooldownUntil - os.clock()),
		dashing = profile.dashUntil > os.clock(),
		stats = profile.stats,
	}
end

return Store
