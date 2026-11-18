-- The one place server state lives. Every module reads and writes player data and
-- configuration through this Store; nothing else keeps a second copy.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)

local Store = {}

Store.Config = Config
Store.Defs = BrainrotDefs

Store.players = {} -- [userId] = player record
Store.slots = {} -- [plotIndex] = { owner = userId|nil, lockedUntil = 0, models = {brainrotId} }
Store.conveyor = {} -- [brainrotId] = { def, mutation, rate, model, z, plotIndexClaim }
Store.wave = {
	phase = "calm",
	endsAt = 0,
	doubleUntil = 0,
	waveNumber = 0,
}
Store.byUser = {} -- [userId] = Player, for lookups after a player leaves

local plotCount = #Config.World.plotCenters
for index = 1, plotCount do
	Store.slots[index] = { owner = nil, lockedUntil = 0, models = {} }
end

local nextBrainrotId = 0

function Store.nextBrainrotId()
	nextBrainrotId += 1
	return nextBrainrotId
end

function Store.newPlayerRecord(player)
	return {
		userId = player.UserId,
		name = player.Name,
		money = Config.Economy.startingMoney,
		lifetime = 0,
		rebirths = 0,
		multiplier = 1,
		plotIndex = nil,
		lastSteal = 0,
		bought = 0,
		joinedAt = os.time(),
	}
end

function Store.record(player)
	local existing = Store.players[player.UserId]
	if existing then
		return existing
	end
	local record = Store.newPlayerRecord(player)
	Store.players[player.UserId] = record
	Store.byUser[player.UserId] = player
	return record
end

function Store.recordFromUserId(userId)
	local record = Store.players[userId]
	if record then
		return record
	end
	local player = Store.byUser[userId]
	if player and player.Parent then
		return Store.record(player)
	end
	return nil
end

function Store.findFreePlot()
	for index = 1, plotCount do
		if Store.slots[index].owner == nil then
			return index
		end
	end
	return nil
end

function Store.claimPlot(player)
	local record = Store.record(player)
	if record.plotIndex then
		return record.plotIndex
	end
	local index = Store.findFreePlot()
	if index == nil then
		return nil
	end
	Store.slots[index].owner = player.UserId
	record.plotIndex = index
	return index
end

function Store.releasePlot(player)
	local record = Store.players[player.UserId]
	if not record or not record.plotIndex then
		return
	end
	local slot = Store.slots[record.plotIndex]
	if slot and slot.owner == player.UserId then
		for _, entry in ipairs(slot.models) do
			if entry.model then
				entry.model:Destroy()
			end
		end
		slot.owner = nil
		slot.models = {}
		slot.lockedUntil = 0
	end
	record.plotIndex = nil
end

function Store.plotSlotOf(plotIndex)
	return Store.slots[plotIndex]
end

function Store.plotIndexOwnerIs(plotIndex, userId)
	local slot = Store.slots[plotIndex]
	return slot ~= nil and slot.owner == userId
end

-- Every brainrot a player owns on their plot, each with its def, mutation and rate.
function Store.ownedBrainrots(player)
	local record = Store.players[player.UserId]
	local out = {}
	if not record or not record.plotIndex then
		return out
	end
	local slot = Store.slots[record.plotIndex]
	if not slot then
		return out
	end
	for index, entry in ipairs(slot.models) do
		table.insert(out, { index = index, entry = entry })
	end
	return out
end

-- Income per second across the plot, before mutation, times the player's multiplier
-- and the event's x2 (when it is running).
function Store.incomePerSecond(player)
	local record = Store.players[player.UserId]
	local out = 0
	for _, owned in ipairs(Store.ownedBrainrots(player)) do
		out += owned.entry.rate
	end
	return out * (record and record.multiplier or 1)
end

function Store.isWaveDouble()
	return Store.wave.doubleUntil > os.clock()
end

function Store.wavePhaseLabel()
	local wave = Store.wave
	if wave.phase == "warning" then
		return "warning", math.max(0, math.ceil(wave.endsAt - os.clock()))
	elseif wave.phase == "sweeping" then
		return "sweeping", math.max(0, math.ceil(wave.endsAt - os.clock()))
	elseif wave.phase == "double" then
		return "double", math.max(0, math.ceil(wave.doubleUntil - os.clock()))
	end
	return "calm", math.max(0, math.ceil(wave.endsAt - os.clock()))
end

function Store.award(player, amount)
	local record = Store.players[player.UserId]
	if not record then
		return 0
	end
	record.money += amount
	record.lifetime += math.max(0, amount)
	-- Money is whole dollars: income ticks can be fractional, the HUD never is.
	record.money = math.floor(record.money + 0.5)
	return record.money
end

function Store.trySpend(player, amount)
	local record = Store.players[player.UserId]
	if not record then
		return false
	end
	if record.money < amount then
		return false
	end
	record.money -= amount
	return true
end

-- A compact snapshot of one player for the HUD, and the world state the client needs.
function Store.snapshotFor(player)
	local record = Store.record(player)
	local phase, secondsLeft = Store.wavePhaseLabel()
	local owned = {}
	for _, item in ipairs(Store.ownedBrainrots(player)) do
		table.insert(owned, {
			name = item.entry.def.name,
			rarity = item.entry.def.rarity,
			mutation = item.entry.mutation,
			rate = item.entry.rate,
			defId = item.entry.def.id,
		})
	end
	local plot = nil
	if record.plotIndex then
		local slot = Store.slots[record.plotIndex]
		plot = {
			index = record.plotIndex,
			lockedSeconds = math.max(0, math.ceil(slot.lockedUntil - os.clock())),
			ownerName = record.name,
			slots = #Config.World.slotOffsets,
			usedSlots = #slot.models,
		}
	end
	return {
		money = record.money,
		multiplier = record.multiplier,
		rebirths = record.rebirths,
		rebirthCost = Store.rebirthCost(player),
		income = Store.incomePerSecond(player),
		incomeDouble = Store.isWaveDouble(),
		plot = plot,
		owned = owned,
		wave = { phase = phase, secondsLeft = secondsLeft, number = Store.wave.waveNumber },
	}
end

function Store.rebirthCost(player)
	local record = Store.record(player)
	return math.floor(Config.Economy.rebirthBaseCost * (Config.Economy.rebirthCostGrowth ^ record.rebirths))
end

Players.PlayerRemoving:Connect(function(player)
	Store.releasePlot(player)
	Store.players[player.UserId] = nil
end)

return Store
