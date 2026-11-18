-- Every money rule in one place: passive income, buying a brainrot off the
-- conveyor, the base lock purchase, rebirths and mutation pricing. Server
-- modules call these; nothing here touches instances except through the
-- callbacks BaseService gives it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local Store = require(script.Parent.Store)

local Economy = {}

-- How often passive income is credited and the HUD is refreshed.
Economy.TickInterval = 0.25

-- Money is a float so fractional rates feel smooth, but the HUD rounds.
function Economy.AddMoney(record, amount)
	record.money = math.max(0, record.money + amount)
	if amount > 0 then
		record.totalEarned += amount
	end
end

function Economy.TrySpend(record, amount)
	if record.money < amount then
		return false
	end
	record.money -= amount
	return true
end

-- A brainrot's price is fixed by its definition, so the ladder on the belt is
-- predictable and a player can always see what the next tier costs.
function Economy.PriceOf(def)
	return def.price
end

function Economy.MutationRate(def, mutation)
	local info = mutation and BrainrotDefs.Mutations[mutation] or nil
	return def.rate * (info and info.rateMultiplier or 1)
end

-- Buy the offer with `offerId` for `player`, placing it in the first free slot
-- on their base. The offer's own model is handed to `placeIntoBase` so the
-- brainrot the player watched walk the belt is the one that walks home.
function Economy.BuyOffer(player, offerId, placeIntoBase)
	local record = Store.GetPlayer(player.UserId)
	if not record then
		return false, "No player record", nil
	end
	local offer = Store.Offers[offerId]
	if not offer then
		return false, "That brainrot is already gone", nil
	end
	local slotIndex = Store.FreeSlotOf(record.plotIndex)
	if not slotIndex then
		return false, "Your base is full. Rebirth for a higher multiplier.", nil
	end
	if record.money < offer.price then
		return false, "Not enough money", nil
	end
	Economy.TrySpend(record, offer.price)

	-- Detach first so the spawner stops steering the model while it flies home.
	offer = Store.DetachOffer(offerId) or offer
	local slot = {
		defId = offer.defId,
		mutation = offer.mutation,
		rate = offer.rate,
	}
	Store.Bases[record.plotIndex].slots[slotIndex] = slot

	local def = BrainrotDefs.Get(offer.defId)
	if placeIntoBase then
		placeIntoBase(record.plotIndex, slotIndex, def, offer.mutation, offer.rate, offer.model)
	end
	return true, "Bought " .. (def and def.name or offer.defId), slotIndex
end

-- The base lock: a timed shield that blocks stealing from the buyer's plot.
function Economy.BuyLock(player)
	local record = Store.GetPlayer(player.UserId)
	if not record then
		return false, "No player record"
	end
	local base = Store.Bases[record.plotIndex]
	if not base then
		return false, "No base"
	end
	if Store.IsBaseLocked(record.plotIndex) then
		return false, "Your base is already locked"
	end
	if not Economy.TrySpend(record, Config.LockCost) then
		return false, "Not enough money for a lock"
	end
	base.lockUntil = os.clock() + Config.LockDuration
	return true, "Base locked for " .. Config.LockDuration .. "s"
end

function Economy.RebirthCost(record)
	return Config.RebirthCost(record.rebirths)
end

-- Rebirth: wipe money, every owned brainrot and the base lock, gain one
-- rebirth level and its permanent multiplier.
function Economy.Rebirth(player, clearBase)
	local record = Store.GetPlayer(player.UserId)
	if not record then
		return false, "No player record"
	end
	local cost = Config.RebirthCost(record.rebirths)
	if record.money < cost then
		return false, "Need " .. cost .. " to rebirth"
	end
	record.money = 0
	record.rebirths += 1
	local base = Store.Bases[record.plotIndex]
	if base then
		base.slots = {}
		base.lockUntil = 0
	end
	if clearBase then
		clearBase(record.plotIndex)
	end
	return true, "Rebirth " .. record.rebirths .. "! Multiplier x" .. string.format("%.2f", Config.MultiplierFor(record.rebirths))
end

-- Adds one interval of passive income to every real player and returns the
-- players whose money changed so the caller can push a snapshot.
function Economy.TickIncome(dt)
	local changed = {}
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local record = Store.Players[player.UserId]
		if record then
			local income = Store.IncomeOf(player)
			if income > 0 then
				Economy.AddMoney(record, income * dt)
				table.insert(changed, player)
			end
		end
	end
	return changed
end

return Economy
