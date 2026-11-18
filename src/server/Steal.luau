-- Stealing: takes a brainrot out of another base (player or rival) and puts it
-- in the thief's base. Respects the base lock, ranges, cooldowns and fills the
-- victim with a small money penalty so being robbed actually stings.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local PlotLayout = require(ReplicatedStorage.Shared.PlotLayout)
local Store = require(script.Parent.Store)
local Bases = require(script.Parent.Bases)
local PlayerService = require(script.Parent.PlayerService)

local Steal = {}

function Steal.canStealFrom(profile, plotIndex: number, slotIndex: number): (boolean, string)
	local plot = PlotLayout.get(plotIndex)
	if not plot then
		return false, "No such base"
	end
	if profile.plotIndex == plotIndex then
		return false, "That is your own base"
	end

	local owner, ownerRecord = Bases.findOwnerOfSlot(plotIndex, slotIndex)
	if owner then
		if not ownerRecord then
			return false, "That slot is empty"
		end
		if Store.hasLock(owner) then
			return false, owner.name .. "'s base is locked"
		end
	else
		local rival, rivalRecord = Bases.findRivalOfSlot(plotIndex, slotIndex)
		if not rival or not rivalRecord then
			return false, "That slot is empty"
		end
	end

	local root = PlayerService.rootFor(profile.userId)
	if root and not PlotLayout.isInside(plotIndex, root.Position, GameConfig.Steal.range) then
		return false, "Get closer to that base"
	end

	return true, ""
end

function Steal.steal(profile, plotIndex: number, slotIndex: number): (boolean, string)
	if os.clock() < profile.stealCooldownUntil then
		return false, "Steal cooling down"
	end
	local ok, reason = Steal.canStealFrom(profile, plotIndex, slotIndex)
	if not ok then
		return false, reason
	end
	local freeSlot = Store.freeSlotIndex(profile)
	if freeSlot == 0 then
		return false, "Your base is full"
	end

	local victimProfile = Bases.findOwnerOfSlot(plotIndex, slotIndex)
	local record
	if victimProfile then
		record = victimProfile.slots[slotIndex]
	else
		local rival = Bases.findRivalOfSlot(plotIndex, slotIndex)
		record = rival and rival.slots[slotIndex]
	end
	if not record then
		return false, "That slot is empty"
	end

	local def = BrainrotDefs.get(record.defId)
	if not def then
		return false, "Unknown brainrot"
	end

	Bases.clearSlotRecord(plotIndex, slotIndex)
	Store.placeSlot(profile, freeSlot, record.defId, record.mutationId)
	profile.stats.steals += 1
	profile.stealCooldownUntil = os.clock() + GameConfig.Steal.cooldown
	Bases.syncPlayer(profile)

	if victimProfile then
		victimProfile.stats.stolen += 1
		local penalty = math.floor(victimProfile.money * GameConfig.Steal.rivalAlarmPenalty)
		victimProfile.money = math.max(0, victimProfile.money - penalty)
		Bases.syncPlayer(victimProfile)
		return true, "Stole " .. def.name .. " from " .. victimProfile.name .. "!"
	end

	return true, "Stole " .. def.name .. " from a rival base!"
end

function Steal.buyLock(profile): (boolean, string)
	if Store.hasLock(profile) then
		return false, "Base already locked"
	end
	if not Store.spendMoney(profile, GameConfig.Lock.cost) then
		return false, "Need $" .. tostring(GameConfig.Lock.cost)
	end
	profile.lockUntil = os.clock() + GameConfig.Lock.duration
	Bases.syncPlayer(profile)
	return true, "Base locked for " .. GameConfig.Lock.duration .. "s"
end

return Steal
