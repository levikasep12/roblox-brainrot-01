-- All money math: passive income, rebirth cost and payout, buy prices and
-- the value of a steal. Nothing else touches profile.money directly.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local Store = require(script.Parent.Store)

local Economy = {}

function Economy.rebirthCost(profile): number
	local growth = GameConfig.Rebirth.costGrowth ^ profile.rebirths
	return math.floor(GameConfig.Rebirth.baseCost * growth)
end

function Economy.rebirthReward(profile): number
	return profile.rebirths + 1
end

function Economy.nextMultiplier(profile): number
	return 1 + (profile.rebirths + 1) * GameConfig.Rebirth.multiplierPerRebirth
end

function Economy.canRebirth(profile): (boolean, string)
	if profile.rebirths >= GameConfig.Rebirth.maxRebirths then
		return false, "Max rebirths reached"
	end
	if Store.slotCount(profile) == 0 then
		return false, "Place a brainrot first"
	end
	local cost = Economy.rebirthCost(profile)
	if profile.money < cost then
		return false, "Need $" .. tostring(cost)
	end
	return true, ""
end

function Economy.rebirth(profile): (boolean, string)
	local ok, reason = Economy.canRebirth(profile)
	if not ok then
		return false, reason
	end
	local cost = Economy.rebirthCost(profile)
	Store.spendMoney(profile, cost)
	profile.rebirths += 1
	profile.stats.rebirths += 1
	profile.multiplier = 1 + profile.rebirths * GameConfig.Rebirth.multiplierPerRebirth
	for slot = 1, GameConfig.StartingSlots do
		profile.slots[slot] = nil
	end
	profile.money = GameConfig.StartingMoney
	profile.lockUntil = 0
	return true, "Rebirth " .. tostring(profile.rebirths) .. "! Income x" .. string.format("%.2f", profile.multiplier)
end

function Economy.sellPrice(profile, def, mutationId: string): number
	local price = BrainrotDefs.priceFor(def, mutationId)
	return math.max(1, math.floor(price * 0.45))
end

function Economy.tickIncome(profile, dt: number, boost: number): number
	local rate = Store.baseIncome(profile) * (boost or 1)
	if rate <= 0 then
		return 0
	end
	local gained = rate * dt
	profile.money += gained
	profile.stats.earned += gained
	return gained
end

return Economy
