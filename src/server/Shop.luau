-- The shop: a catalog a player can buy directly (the "next tier" ladder),
-- priced above the belt so waiting for a spawn is always the cheaper path.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local Store = require(script.Parent.Store)
local Bases = require(script.Parent.Bases)

local Shop = {}

Shop.Markup = 1.35

function Shop.catalogFor(profile)
	local list = {}
	local nextRarityIndex = 1
	local bestPlaced = 0
	for slot = 1, GameConfig.StartingSlots do
		local record = profile.slots[slot]
		if record then
			local def = BrainrotDefs.get(record.defId)
			if def then
				bestPlaced = math.max(bestPlaced, BrainrotDefs.rarityIndex(def.rarity))
			end
		end
	end
	nextRarityIndex = math.min(#GameConfig.RarityOrder, bestPlaced + 1)

	for _, rarity in ipairs(GameConfig.RarityOrder) do
		local rarityIndex = BrainrotDefs.rarityIndex(rarity)
		if rarityIndex >= nextRarityIndex and rarityIndex <= nextRarityIndex + 1 then
			for _, def in ipairs(BrainrotDefs.ByRarity[rarity] or {}) do
				table.insert(list, {
					defId = def.id,
					name = def.name,
					rarity = def.rarity,
					rate = def.rate,
					price = math.floor(def.price * Shop.Markup),
					blurb = def.blurb,
				})
			end
		end
	end

	if #list == 0 then
		local def = BrainrotDefs.ByRarity.Mythic[1]
		table.insert(list, {
			defId = def.id,
			name = def.name,
			rarity = def.rarity,
			rate = def.rate,
			price = math.floor(def.price * Shop.Markup),
			blurb = def.blurb,
		})
	end
	return list
end

function Shop.buy(profile, defId: string): (boolean, string)
	local def = BrainrotDefs.get(defId)
	if not def then
		return false, "Unknown brainrot"
	end
	local freeSlot = Store.freeSlotIndex(profile)
	if freeSlot == 0 then
		return false, "Your base is full"
	end
	local price = math.floor(def.price * Shop.Markup)
	if profile.money < price then
		return false, "Need $" .. tostring(price)
	end
	Store.spendMoney(profile, price)
	Store.placeSlot(profile, freeSlot, def.id, "Normal")
	Bases.syncPlayer(profile)
	return true, "Bought " .. def.name
end

return Shop
