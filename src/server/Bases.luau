-- Owns every 3D brainrot standing on a base: builds slot models, refreshes
-- them when a slot changes, and paints the base lock barrier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local BrainrotModel = require(ReplicatedStorage.Shared.BrainrotModel)
local PlotLayout = require(ReplicatedStorage.Shared.PlotLayout)
local WorldRefs = require(ReplicatedStorage.Shared.WorldRefs)
local Store = require(script.Parent.Store)

local Bases = {}

local plotFolders = {}
local slotModels = {}
local lockVisual = {}
local pendingSyncs = {}

local function plotFolder(plotIndex: number): Model?
	local plots = WorldRefs.plots()
	if not plots then
		return nil
	end
	for _, candidate in ipairs(plots:GetChildren()) do
		if candidate:IsA("Model") and candidate:GetAttribute("PlotIndex") == plotIndex then
			return candidate
		end
	end
	return nil
end

function Bases.plotFolder(plotIndex: number): Model?
	if plotFolders[plotIndex] and plotFolders[plotIndex].Parent then
		return plotFolders[plotIndex]
	end
	local found = plotFolder(plotIndex)
	plotFolders[plotIndex] = found
	return found
end

local function slotContainer(plotIndex: number): Folder?
	local plot = Bases.plotFolder(plotIndex)
	if not plot then
		return nil
	end
	local existing = plot:FindFirstChild("Brainrots")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "Brainrots"
	created.Parent = plot
	return created
end

local function clearModel(plotIndex: number, slotIndex: number)
	local key = plotIndex * 100 + slotIndex
	local old = slotModels[key]
	if old then
		old:Destroy()
		slotModels[key] = nil
	end
end

function Bases.clearPlot(plotIndex: number)
	for slotIndex = 1, GameConfig.StartingSlots do
		clearModel(plotIndex, slotIndex)
	end
end

function Bases.buildSlot(plotIndex: number, slotIndex: number, defId: string, mutationId: string)
	clearModel(plotIndex, slotIndex)
	local def = BrainrotDefs.get(defId)
	local container = slotContainer(plotIndex)
	if not def or not container then
		return
	end

	local model = BrainrotModel.build(def)
	model.Name = string.format("%s_%d_%d", defId, plotIndex, slotIndex)
	model:SetAttribute("DefId", defId)
	model:SetAttribute("MutationId", mutationId)
	model:SetAttribute("PlotIndex", plotIndex)
	model:SetAttribute("SlotIndex", slotIndex)

	local basePosition = PlotLayout.slotPosition(plotIndex, slotIndex)
	model:PivotTo(CFrame.new(basePosition) * CFrame.Angles(0, math.rad(math.random(0, 359)), 0))
	BrainrotModel.applyMutation(model, mutationId)
	BrainrotModel.addLabel(model, def, mutationId)

	model.Parent = container
	slotModels[plotIndex * 100 + slotIndex] = model

	local pad = Bases.plotFolder(plotIndex)
	if pad then
		local ring = pad:FindFirstChild("SlotRing" .. slotIndex)
		if ring and ring:IsA("BasePart") then
			ring.Color = BrainrotDefs.rarityColor(def.rarity)
		end
	end
end

function Bases.syncPlayer(profile)
	if profile.plotIndex == 0 then
		return
	end
	if not Bases.plotFolder(profile.plotIndex) then
		pendingSyncs[profile.userId] = true
		return
	end
	pendingSyncs[profile.userId] = nil
	for slotIndex = 1, GameConfig.StartingSlots do
		local record = profile.slots[slotIndex]
		local key = profile.plotIndex * 100 + slotIndex
		local existing = slotModels[key]
		if record then
			if not existing or existing:GetAttribute("DefId") ~= record.defId or existing:GetAttribute("MutationId") ~= record.mutationId then
				Bases.buildSlot(profile.plotIndex, slotIndex, record.defId, record.mutationId)
			end
		elseif existing then
			clearModel(profile.plotIndex, slotIndex)
		end
	end
	Bases.updateSign(profile)
	Bases.setLockVisual(profile)
end

function Bases.retryPending()
	for userId in pairs(pendingSyncs) do
		local profile = Store.getPlayer(userId)
		if profile then
			Bases.syncPlayer(profile)
		else
			pendingSyncs[userId] = nil
		end
	end
end

function Bases.updateSign(profile)
	local plot = Bases.plotFolder(profile.plotIndex)
	if not plot then
		return
	end
	local sign = plot:FindFirstChild("OwnerSign")
	if not sign then
		return
	end
	local locked = Store.hasLock(profile)
	local text = string.upper(profile.name) .. (if locked then "  [LOCKED]" else "")
	local color = if locked then Color3.fromRGB(120, 255, 178) else Color3.fromRGB(255, 255, 255)
	for _, surfaceName in ipairs({ "Face", "FaceBack" }) do
		local face = sign:FindFirstChild(surfaceName)
		local label = face and face:FindFirstChild("Text")
		if label and label:IsA("TextLabel") then
			label.Text = text
			label.TextColor3 = color
		end
	end
end

function Bases.setLockVisual(profile)
	local plot = Bases.plotFolder(profile.plotIndex)
	if not plot then
		return
	end
	local locked = Store.hasLock(profile)
	if lockVisual[profile.plotIndex] == locked then
		if locked then
			Bases.updateSign(profile)
		end
		return
	end
	lockVisual[profile.plotIndex] = locked
	local barrier = plot:FindFirstChild("LockBarrier")
	if barrier and barrier:IsA("BasePart") then
		local target = if locked then 0.35 else 1
		local tween = game:GetService("TweenService"):Create(barrier, TweenInfo.new(0.4), { Transparency = target })
		tween:Play()
		barrier.CanQuery = locked
	end
	Bases.updateSign(profile)
end

function Bases.syncRival(rival)
	for slotIndex = 1, GameConfig.StartingSlots do
		local record = rival.slots[slotIndex]
		if record then
			local key = rival.plotIndex * 100 + slotIndex
			local existing = slotModels[key]
			if not existing or existing:GetAttribute("DefId") ~= record.defId or existing:GetAttribute("MutationId") ~= record.mutationId then
				Bases.buildSlot(rival.plotIndex, slotIndex, record.defId, record.mutationId)
			end
		else
			clearModel(rival.plotIndex, slotIndex)
		end
	end
end

function Bases.findOwnerOfSlot(plotIndex: number, slotIndex: number)
	for _, profile in pairs(Store.state.players) do
		if profile.plotIndex == plotIndex then
			local record = profile.slots[slotIndex]
			if record then
				return profile, record
			end
		end
	end
	return nil, nil
end

function Bases.findRivalOfSlot(plotIndex: number, slotIndex: number)
	for _, rival in pairs(Store.state.rivals) do
		if rival.plotIndex == plotIndex then
			local record = rival.slots[slotIndex]
			if record then
				return rival, record
			end
		end
	end
	return nil, nil
end

function Bases.clearSlotRecord(plotIndex: number, slotIndex: number)
	local owner = Bases.findOwnerOfSlot(plotIndex, slotIndex)
	if owner then
		owner.slots[slotIndex] = nil
		Bases.syncPlayer(owner)
		return owner
	end
	local rival = Bases.findRivalOfSlot(plotIndex, slotIndex)
	if rival then
		rival.slots[slotIndex] = nil
		Bases.syncRival(rival)
		return rival
	end
	return nil
end

return Bases
