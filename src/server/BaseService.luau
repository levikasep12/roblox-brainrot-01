-- Owns the visible side of bases: placing a bought brainrot into a slot,
-- clearing a slot when it is stolen or a rebirth wipes it, repainting plot
-- signs and slot glows, and creating the demo rival bases so the map is not
-- empty with one player online.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local BrainrotDefs = require(Shared.BrainrotDefs)
local BrainrotModel = require(Shared.BrainrotModel)
local WorldBuilder = require(script.Parent.WorldBuilder)
local Store = require(script.Parent.Store)

local BaseService = {}

local function slotModelName(plotIndex, slotIndex)
	return "Brainrot_" .. plotIndex .. "_" .. slotIndex
end

local function plotModel(plotIndex)
	return workspace:FindFirstChild("Plot" .. plotIndex)
end

function BaseService.RefreshPlotSign(plotIndex)
	local base = Store.GetBase(plotIndex)
	if not base then
		return
	end
	if base.ownerUserId then
		local locked = Store.IsBaseLocked(plotIndex)
		local text = "PLOT " .. plotIndex .. "\n" .. string.upper(base.ownerName)
		if locked then
			text = text .. "\nLOCKED"
		end
		WorldBuilder.SetPlotLabel(plotIndex, text, locked and Color3.fromRGB(255, 130, 130) or Color3.fromRGB(150, 240, 255))
	else
		WorldBuilder.SetPlotLabel(plotIndex, "PLOT " .. plotIndex .. "\nUNCLAIMED", Color3.fromRGB(150, 160, 180))
	end
end

-- Places a bought brainrot on the pad for its slot. When `existingModel` is
-- given (the conveyor model that was just bought) it is the one that lands,
-- so the character the player watched is the character they now own.
function BaseService.PlaceInSlot(plotIndex, slotIndex, def, mutation, rate, existingModel)
	local plot = plotModel(plotIndex)
	if not plot then
		return
	end
	local slotPos = Config.SlotPosition(plotIndex, slotIndex)
	local frame = BrainrotModel.FacingCFrame(slotPos + Vector3.new(0, 0.4, 0), Config.SlotFacing(plotIndex))

	local model = existingModel
	if model then
		local start = model:GetPivot()
		local steps = 26
		task.spawn(function()
			for step = 1, steps do
				if not model.Parent then
					return
				end
				local alpha = step / steps
				local eased = 1 - (1 - alpha) ^ 3
				local lift = math.sin(alpha * math.pi) * 9
				model:PivotTo(start:Lerp(frame, eased) + Vector3.new(0, lift, 0))
				task.wait(0.028)
			end
			BaseService.SettleInSlot(model, plotIndex, slotIndex, def)
		end)
	else
		local built = BrainrotModel.Build(def, mutation, frame, rate)
		model = built
		BaseService.SettleInSlot(model, plotIndex, slotIndex, def)
	end

	model.Name = slotModelName(plotIndex, slotIndex)
	model:SetAttribute("SlotIndex", slotIndex)
	model:SetAttribute("PlotIndex", plotIndex)
	if model.Parent ~= plot then
		model.Parent = plot
	end

	local rarityColor = BrainrotDefs.RarityColor[def.rarity] or Color3.fromRGB(255, 255, 255)
	WorldBuilder.SetSlotGlow(plotIndex, slotIndex, rarityColor, 0.15)
	return model
end

-- Shared finishing step: snap to the pad, give it its prompts and light it.
function BaseService.SettleInSlot(model, plotIndex, slotIndex, def)
	if not model.Parent or not model.PrimaryPart then
		return
	end
	local slotPos = Config.SlotPosition(plotIndex, slotIndex)
	local frame = BrainrotModel.FacingCFrame(slotPos + Vector3.new(0, 0.4, 0), Config.SlotFacing(plotIndex))
	model:PivotTo(frame)

	local root = model.PrimaryPart
	local prompt = root:FindFirstChild("InspectBrainrot")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "InspectBrainrot"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.ActionText = "Inspect"
		prompt.Parent = root
	end
	prompt.ObjectText = (def and (def.name .. "  " .. def.rarity)) or "Brainrot"
end

function BaseService.ClearSlot(plotIndex, slotIndex)
	local plot = plotModel(plotIndex)
	if plot then
		local existing = plot:FindFirstChild(slotModelName(plotIndex, slotIndex))
		if existing then
			existing:Destroy()
		end
	end
	WorldBuilder.SetSlotGlow(plotIndex, slotIndex, Color3.fromRGB(60, 68, 88), 0.45)
end

-- Clears a pad after its brainrot has already been lifted out of it.
function BaseService.ClearSlotVisualOnly(plotIndex, slotIndex)
	WorldBuilder.SetSlotGlow(plotIndex, slotIndex, Color3.fromRGB(60, 68, 88), 0.45)
end

-- Flies an existing model from where it stands to another plot's slot, then
-- renames and re-prompts it so the new owner can inspect it.
function BaseService.FlyModelToSlot(model, destPlotIndex, destSlotIndex, def)
	local start = model:GetPivot()
	local slotPos = Config.SlotPosition(destPlotIndex, destSlotIndex)
	local goal = BrainrotModel.FacingCFrame(slotPos + Vector3.new(0, 0.4, 0), Config.SlotFacing(destPlotIndex))
	local steps = 22
	task.spawn(function()
		for step = 1, steps do
			if not model.Parent then
				return
			end
			local alpha = step / steps
			local eased = 1 - (1 - alpha) ^ 3
			local lift = math.sin(alpha * math.pi) * 7
			local pivot = start:Lerp(goal, eased) + Vector3.new(0, lift, 0)
			model:PivotTo(pivot)
			task.wait(0.03)
		end
		model.Name = slotModelName(destPlotIndex, destSlotIndex)
		local newPlot = plotModel(destPlotIndex)
		if newPlot and model.Parent ~= newPlot then
			model.Parent = newPlot
		end
		model:SetAttribute("PlotIndex", destPlotIndex)
		model:SetAttribute("SlotIndex", destSlotIndex)
		BaseService.SettleInSlot(model, destPlotIndex, destSlotIndex, def)
		if def then
			local rarityColor = BrainrotDefs.RarityColor[def.rarity] or Color3.fromRGB(255, 255, 255)
			WorldBuilder.SetSlotGlow(destPlotIndex, destSlotIndex, rarityColor, 0.15)
			BaseService.Burst(slotPos + Vector3.new(0, 3, 0), rarityColor, 22)
		end
	end)
end

function BaseService.ClearBaseVisuals(plotIndex)
	for slotIndex = 1, Config.SlotsPerPlot do
		BaseService.ClearSlot(plotIndex, slotIndex)
	end
end

-- Rewrites every housed brainrot's $/s label so it shows what the owner really
-- earns, rebirth multiplier included.
function BaseService.RefreshSlotLabels(plotIndex, multiplier)
	local plot = plotModel(plotIndex)
	if not plot then
		return
	end
	for slotIndex = 1, Config.SlotsPerPlot do
		local model = plot:FindFirstChild(slotModelName(plotIndex, slotIndex))
		if model then
			local baseRate = model:GetAttribute("Rate") or 0
			BrainrotModel.SetLabelRate(model, baseRate * multiplier)
		end
	end
end

-- A short, cheap particle burst built from a Part + ParticleEmitter. No asset
-- ids: the emitter uses Roblox's default sparkle texture.
function BaseService.Burst(position, color, count)
	local holder = Instance.new("Part")
	holder.Name = "Burst"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.5, 0.5, 0.5)
	holder.Position = position
	holder.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Pop"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.8
	emitter.Lifetime = NumberRange.new(0.35, 0.7)
	emitter.Speed = NumberRange.new(9, 16)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = holder
	emitter:Emit(count or 20)
	game:GetService("Debris"):AddItem(holder, 1.5)
end

-- Puts the demo rivals' brainrots on their plots, so a lone player still has
-- something to steal and someone to compete with.
function BaseService.SeedRivals()
	for _, rival in ipairs(Config.DemoRivals) do
		local base = Store.GetBase(rival.plotIndex)
		if base and not base.ownerUserId then
			base.ownerName = rival.name
			base.rival = true
			for index, defId in ipairs(rival.brainrots) do
				local def = BrainrotDefs.Get(defId)
				if def then
					local rate = def.rate
					base.slots[index] = { defId = defId, rate = rate }
					BaseService.PlaceInSlot(rival.plotIndex, index, def, nil, rate)
				end
			end
			BaseService.RefreshPlotSign(rival.plotIndex)
		end
	end
end

-- The lock expiry timer for one plot: repaint the sign when it runs out.
function BaseService.WatchLock(plotIndex)
	task.spawn(function()
		while true do
			task.wait(1)
			local base = Store.GetBase(plotIndex)
			if not base then
				return
			end
			if base.lockUntil > 0 and os.clock() >= base.lockUntil then
				base.lockUntil = 0
				BaseService.RefreshPlotSign(plotIndex)
				return
			end
			if base.lockUntil <= 0 then
				return
			end
		end
	end)
end

return BaseService
