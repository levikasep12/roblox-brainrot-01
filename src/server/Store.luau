-- The one place the server keeps game state: every player's money, rebirths,
-- plot and owned brainrots, every base plot, the conveyor offers and the
-- hazard wave. Nothing outside this module writes those tables; the other
-- server modules ask it questions and call its mutators.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotDefs = require(game:GetService("ReplicatedStorage").Shared.BrainrotDefs)

local Store = {}

Store.Players = {} -- [userId] = PlayerRecord
Store.Bases = {} -- [plotIndex] = BaseRecord
Store.Offers = {} -- [offerId] = OfferRecord
Store.NextOfferId = 1
Store.Wave = {
	active = false,
	startedAt = 0,
	index = 0,
	warning = 0,
}

local function newBase(plotIndex, ownerUserId, ownerName, rival)
	return {
		plotIndex = plotIndex,
		ownerUserId = ownerUserId,
		ownerName = ownerName,
		rival = rival or false,
		slots = {},
		lockUntil = 0,
	}
end

function Store.ResetBases()
	Store.Bases = {}
	for plotIndex = 1, Config.PlotCount do
		Store.Bases[plotIndex] = newBase(plotIndex, nil, "Unclaimed", true)
	end
end

function Store.GetBase(plotIndex)
	return Store.Bases[plotIndex]
end

function Store.GetPlayer(userId)
	return Store.Players[userId]
end

function Store.CreatePlayer(player, plotIndex)
	local record = {
		userId = player.UserId,
		name = player.Name,
		plotIndex = plotIndex,
		money = Config.StartingMoney,
		rebirths = 0,
		totalEarned = 0,
		lastSteal = -math.huge,
		joinedAt = os.clock(),
	}
	Store.Players[player.UserId] = record
	Store.Bases[plotIndex] = newBase(plotIndex, player.UserId, player.Name, false)
	return record
end

function Store.RemovePlayer(player)
	local record = Store.Players[player.UserId]
	if record then
		local base = Store.Bases[record.plotIndex]
		if base then
			Store.Bases[record.plotIndex] = newBase(record.plotIndex, nil, "Unclaimed", true)
		end
		Store.Players[player.UserId] = nil
	end
end

-- The first plot no real player owns. Plots the demo rivals stocked are
-- offered last so a new player never has their base cleared on join.
function Store.FindFreePlot()
	local stocked = nil
	for plotIndex = 1, Config.PlotCount do
		local base = Store.Bases[plotIndex]
		if base and base.ownerUserId == nil then
			if Store.BaseRateOf(base) == 0 then
				return plotIndex
			end
			stocked = stocked or plotIndex
		end
	end
	return stocked
end

-- Total money per second a player earns from every brainrot on their base,
-- mutation and rebirth multiplier applied.
function Store.IncomeOf(player)
	local record = Store.Players[player.UserId]
	if not record then
		return 0
	end
	local base = Store.Bases[record.plotIndex]
	if not base then
		return 0
	end
	local baseRate = 0
	for _, slot in pairs(base.slots) do
		baseRate += slot.rate
	end
	return baseRate * Config.MultiplierFor(record.rebirths)
end

function Store.BaseRateOf(base)
	local total = 0
	for _, slot in pairs(base.slots) do
		total += slot.rate
	end
	return total
end

function Store.FreeSlotOf(plotIndex)
	local base = Store.Bases[plotIndex]
	if not base then
		return nil
	end
	for slotIndex = 1, Config.SlotsPerPlot do
		if not base.slots[slotIndex] then
			return slotIndex
		end
	end
	return nil
end

function Store.AddOffer(def, mutation, price, rate, model)
	local offer = {
		id = Store.NextOfferId,
		defId = def.id,
		mutation = mutation,
		price = price,
		rate = rate,
		model = model,
		progress = 0,
		speed = Config.ConveyorSpeed,
	}
	Store.NextOfferId += 1
	Store.Offers[offer.id] = offer
	return offer
end

function Store.RemoveOffer(offerId)
	local offer = Store.Offers[offerId]
	if offer and offer.model then
		offer.model:Destroy()
	end
	Store.Offers[offerId] = nil
end

-- Takes an offer out of the book and hands back its record (with the model
-- still in the world) so the caller can animate it home first.
function Store.DetachOffer(offerId)
	local offer = Store.Offers[offerId]
	Store.Offers[offerId] = nil
	return offer
end

function Store.ClearOffers()
	for offerId in pairs(Store.Offers) do
		Store.RemoveOffer(offerId)
	end
end

function Store.PlotLockRemaining(plotIndex)
	local base = Store.Bases[plotIndex]
	if not base then
		return 0
	end
	return math.max(0, base.lockUntil - os.clock())
end

function Store.IsBaseLocked(plotIndex)
	return Store.PlotLockRemaining(plotIndex) > 0
end

-- The public view of one base, for the steal board and the owner HUD.
function Store.BaseSummary(base)
	local slots = {}
	for slotIndex = 1, Config.SlotsPerPlot do
		local slot = base.slots[slotIndex]
		if slot then
			local def = BrainrotDefs.Get(slot.defId)
			table.insert(slots, {
				index = slotIndex,
				defId = slot.defId,
				name = def and def.name or slot.defId,
				rarity = def and def.rarity or "Common",
				mutation = slot.mutation,
				rate = slot.rate,
			})
		end
	end
	return {
		plotIndex = base.plotIndex,
		ownerName = base.ownerName,
		locked = Store.IsBaseLocked(base.plotIndex),
		lockRemaining = Store.PlotLockRemaining(base.plotIndex),
		rival = base.rival,
		slots = slots,
		rate = Store.BaseRateOf(base),
	}
end

-- Everything one client needs to draw the HUD and the shop, sent on change
-- and on a slow heartbeat.
function Store.SnapshotFor(player)
	local record = Store.Players[player.UserId]
	if not record then
		return nil
	end
	local offers = {}
	for _, offer in pairs(Store.Offers) do
		local def = BrainrotDefs.Get(offer.defId)
		if def then
			table.insert(offers, {
				id = offer.id,
				defId = offer.defId,
				name = def.name,
				rarity = def.rarity,
				mutation = offer.mutation,
				price = offer.price,
				rate = offer.rate,
			})
		end
	end
	table.sort(offers, function(a, b)
		return a.price < b.price
	end)

	local bases = {}
	for plotIndex = 1, Config.PlotCount do
		local base = Store.Bases[plotIndex]
		if base then
			table.insert(bases, Store.BaseSummary(base))
		end
	end

	local recordBase = Store.Bases[record.plotIndex]
	local mySlots = {}
	if recordBase then
		for slotIndex = 1, Config.SlotsPerPlot do
			local slot = recordBase.slots[slotIndex]
			if slot then
				local def = BrainrotDefs.Get(slot.defId)
				mySlots[slotIndex] = {
					defId = slot.defId,
					name = def and def.name or slot.defId,
					rarity = def and def.rarity or "Common",
					mutation = slot.mutation,
					rate = slot.rate,
				}
			end
		end
	end

	return {
		money = record.money,
		income = Store.IncomeOf(player),
		rebirths = record.rebirths,
		multiplier = Config.MultiplierFor(record.rebirths),
		rebirthCost = Config.RebirthCost(record.rebirths),
		plotIndex = record.plotIndex,
		lockCost = Config.LockCost,
		lockRemaining = Store.PlotLockRemaining(record.plotIndex),
		mySlots = mySlots,
		offers = offers,
		bases = bases,
		wave = {
			active = Store.Wave.active,
			warning = Store.Wave.warning,
		},
	}
end

return Store
