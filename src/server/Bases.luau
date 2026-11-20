-- Owns the six plots: claiming one on join, granting the free starter brainrot so a
-- fresh base is never empty, placing a bought brainrot on a free slot, the base lock
-- that stops stealing, and rebuilding the slot props on demand.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Store = require(script.Parent.Store)
local BrainrotModel = require(ReplicatedStorage.Shared.BrainrotModel)

local Bases = {}

Bases.plotParts = {}

function Bases.setPlotParts(parts)
	Bases.plotParts = parts
end

-- The surface a brainrot stands on: the slot pad's top. The plot top is y = 1.2 and the
-- pad is 0.5 tall centred at y = 1.45, so its top is y = 1.7.
local SLOT_SURFACE_Y = 1.7

-- Where a brainrot's pivot goes so it stands on its slot pad. The model reports how far
-- above its own base its pivot sits (BrainrotModel sets StandOffset), so a tall hat or a
-- small cone both rest on the pad instead of sinking or floating.
function Bases.slotWorldPosition(plotIndex, slotIndex, model)
	local config = Store.Config.World
	local center = config.plotCenters[plotIndex]
	local offset = config.slotOffsets[slotIndex]
	if not center or not offset then
		return nil
	end
	local stand = 1.7
	if model and model:GetAttribute("StandOffset") then
		stand = model:GetAttribute("StandOffset")
	end
	return center + offset + Vector3.new(0, SLOT_SURFACE_Y + stand, 0)
end

function Bases.slotPad(plotIndex, slotIndex)
	local entry = Bases.plotParts[plotIndex]
	if not entry then
		return nil
	end
	return entry.slots[slotIndex]
end

-- Claims a plot on join, hands over the free starter brainrot so the base is populated
-- (and earning) from the first second, then paints the sign with the owner's name.
function Bases.onPlayerJoin(player)
	local index = Store.claimPlot(player)
	if index == nil then
		return
	end
	local entry = Bases.plotParts[index]
	if entry and entry.sign then
		for _, gui in ipairs(entry.sign:GetChildren()) do
			if gui:IsA("SurfaceGui") then
				local textLabel = gui:FindFirstChildOfClass("TextLabel")
				if textLabel then
					textLabel.Text = string.upper(player.Name) .. "'S BASE"
				end
			end
		end
	end
	if Store.Config.Conveyor.starterGrant and #Store.ownedBrainrots(player) == 0 then
		local starter = Store.Defs.starter()
		Bases.placeBrainrot(player, {
			brainrotId = Store.nextBrainrotId(),
			def = starter,
			mutation = nil,
			rate = starter.rate,
		})
	end
end

-- Places a brainrot entry on the first free slot of the player's plot.
function Bases.placeBrainrot(player, entry)
	local record = Store.record(player)
	if not record.plotIndex then
		return false, "No base"
	end
	local slot = Store.slots[record.plotIndex]
	if #slot.models >= #Store.Config.World.slotOffsets then
		return false, "All slots full"
	end
	local slotIndex = #slot.models + 1
	local model = BrainrotModel.build(entry.def, math.floor(entry.rate + 0.5), entry.mutation)
	model.Name = entry.def.id
	local position = Bases.slotWorldPosition(record.plotIndex, slotIndex, model)
	model:PivotTo(CFrame.new(position))
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("BrainrotId", entry.brainrotId)
	model.Parent = workspace:FindFirstChild("Arena") or workspace
	entry.model = model
	entry.slotIndex = slotIndex
	table.insert(slot.models, entry)

	local pad = Bases.slotPad(record.plotIndex, slotIndex)
	if pad then
		pad.Color = Store.Defs.RarityColors[entry.def.rarity] or pad.Color
	end
	return true, slotIndex
end

-- Removes a brainrot from a plot by its index in the slot list, destroying its model.
function Bases.removeAt(player, slotIndex)
	local record = Store.players[player.UserId]
	if not record or not record.plotIndex then
		return nil
	end
	local slot = Store.slots[record.plotIndex]
	local entry = slot.models[slotIndex]
	if not entry then
		return nil
	end
	table.remove(slot.models, slotIndex)
	if entry.model then
		entry.model:Destroy()
	end
	Bases.refreshSlotPads(player)
	return entry
end

-- After a removal, slide models down so slots stay contiguous and repaint the pads.
function Bases.refreshSlotPads(player)
	local record = Store.players[player.UserId]
	if not record or not record.plotIndex then
		return
	end
	local slot = Store.slots[record.plotIndex]
	for index, entry in ipairs(slot.models) do
		entry.slotIndex = index
		local position = Bases.slotWorldPosition(record.plotIndex, index, entry.model)
		if position and entry.model then
			entry.model:PivotTo(CFrame.new(position))
		end
	end
	for index = 1, #Store.Config.World.slotOffsets do
		local pad = Bases.slotPad(record.plotIndex, index)
		local entry = slot.models[index]
		if pad then
			pad.Color = entry and (Store.Defs.RarityColors[entry.def.rarity] or pad.Color) or Color3.fromRGB(52, 58, 84)
		end
	end
end

function Bases.lockState(plotIndex)
	local slot = Store.slots[plotIndex]
	if not slot then
		return 0
	end
	return math.max(0, math.ceil(slot.lockedUntil - os.clock()))
end

-- Buys or extends the plot lock: no one can steal while it runs.
function Bases.toggleLock(player)
	local record = Store.record(player)
	if not record.plotIndex then
		return false, "No base"
	end
	local slot = Store.slots[record.plotIndex]
	local cost = Store.Config.Economy.lockCost
	if not Store.trySpend(player, cost) then
		return false, string.format("Lock costs $%d", cost)
	end
	local seconds = Store.Config.Economy.lockSeconds
	slot.lockedUntil = math.max(slot.lockedUntil, os.clock()) + seconds
	return true, string.format("Base locked for %ds", seconds)
end

return Bases
