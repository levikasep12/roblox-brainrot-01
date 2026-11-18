-- Stealing: a player walks onto someone else's plot, holds the "Steal"
-- prompt on a housed brainrot and takes it, unless the base is locked, the
-- thief is on cooldown, or their own base has no free slot. The stolen model
-- flies from the victim's pad to the thief's pad. Accessories and rarity
-- labels come along because the whole Model is re-parented.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local BrainrotDefs = require(Shared.BrainrotDefs)
local Store = require(script.Parent.Store)
local BaseService = require(script.Parent.BaseService)

local Steal = {}

-- Called by the server's prompt handler with a part inside a plot.
function Steal.StealSlot(thief, plotIndex, slotIndex)
	local record = Store.GetPlayer(thief.UserId)
	if not record then
		return false, "No player record"
	end
	local base = Store.GetBase(plotIndex)
	if not base then
		return false, "No such base"
	end
	if base.ownerUserId == record.userId then
		return false, "That is your own base"
	end
	local slot = base.slots[slotIndex]
	if not slot then
		return false, "That slot is empty"
	end
	if Store.IsBaseLocked(plotIndex) then
		return false, "That base is locked for " .. math.ceil(Store.PlotLockRemaining(plotIndex)) .. "s"
	end
	local now = os.clock()
	if now - record.lastSteal < Config.StealCooldown then
		return false, "Steal cooldown: " .. math.ceil(Config.StealCooldown - (now - record.lastSteal)) .. "s"
	end
	local freeSlot = Store.FreeSlotOf(record.plotIndex)
	if not freeSlot then
		return false, "Your base is full"
	end

	record.lastSteal = now
	base.slots[slotIndex] = nil
	Store.Bases[record.plotIndex].slots[freeSlot] = slot

	local def = BrainrotDefs.Get(slot.defId)
	local sourceModel = workspace:FindFirstChild("Plot" .. plotIndex)
	sourceModel = sourceModel and sourceModel:FindFirstChild("Brainrot_" .. plotIndex .. "_" .. slotIndex)
	if sourceModel then
		BaseService.FlyModelToSlot(sourceModel, record.plotIndex, freeSlot, def)
	end
	BaseService.ClearSlotVisualOnly(plotIndex, slotIndex)
	BaseService.RefreshPlotSign(plotIndex)
	BaseService.RefreshPlotSign(record.plotIndex)

	return true, "Stole " .. (def and def.name or slot.defId), freeSlot
end

-- Whether a base may be stolen from right now, for the client's prompt text.
function Steal.CanSteal(thief, plotIndex)
	local base = Store.GetBase(plotIndex)
	if not base then
		return false, "No base"
	end
	local record = Store.GetPlayer(thief.UserId)
	if not record then
		return false, "No player record"
	end
	if base.ownerUserId == record.userId then
		return false, "Your base"
	end
	return true, "Steal"
end

return Steal
