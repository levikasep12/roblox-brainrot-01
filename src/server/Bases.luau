-- Bases: owns what stands on every plot. It draws a brainrot model into a slot
-- pad, clears a slot, animates idle bobbing and raises/lowers the lock shield.
-- The module is pure presentation of state the Store already holds: it never
-- decides who owns what, it just shows it, which keeps the server authoritative
-- and the rendering in one place.

local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotDefs = require(game:GetService("ReplicatedStorage").Shared.BrainrotDefs)
local ModelBuilder = require(script.Parent.ModelBuilder)
local Store = require(script.Parent.Store)

local Bases = {}

local worldHandles: any
local displayFolder: Folder
local placed: { [number]: { [number]: any } } = {}
local shields: { [number]: Part } = {}

function Bases.init(handles: any)
	worldHandles = handles
	displayFolder = Instance.new("Folder")
	displayFolder.Name = "BaseDisplays"
	displayFolder.Parent = workspace
	for plotIndex = 1, Config.PlotCount do
		placed[plotIndex] = {}
	end
end

function Bases.slotPosition(plotIndex: number, slotIndex: number): Vector3?
	local plot = worldHandles.plots[plotIndex]
	if not plot or not plot.pads[slotIndex] then
		return nil
	end
	return plot.pads[slotIndex].position
end

function Bases.plotCentre(plotIndex: number): Vector3?
	local plot = worldHandles.plots[plotIndex]
	return plot and plot.centre or nil
end

function Bases.setSlot(plotIndex: number, slotIndex: number, defId: string, mutationId: string, ownerName: string)
	local position = Bases.slotPosition(plotIndex, slotIndex)
	if not position then
		return
	end
	Bases.clearSlot(plotIndex, slotIndex)

	local model = ModelBuilder.build(defId, mutationId)
	model.Name = ("Base_%d_%d"):format(plotIndex, slotIndex)
	model.Parent = displayFolder
	model:PivotTo(CFrame.new(position))
	model:ScaleTo(1.35)

	local ownerLabel = Instance.new("BillboardGui")
	ownerLabel.Name = "OwnerLabel"
	ownerLabel.Size = UDim2.fromOffset(150, 20)
	local labelHeight = (model:GetAttribute("LabelHeight") or 4) * 1.35 + 1.4
	ownerLabel.StudsOffsetWorldSpace = Vector3.new(0, labelHeight + 3.2, 0)
	ownerLabel.AlwaysOnTop = false
	ownerLabel.MaxDistance = 80
	ownerLabel.LightInfluence = 0
	ownerLabel.Adornee = model.PrimaryPart
	ownerLabel.Parent = model.PrimaryPart

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = 11
	text.TextColor3 = Color3.fromRGB(210, 232, 255)
	text.TextStrokeTransparency = 0.4
	text.Text = ("%s's base"):format(ownerName)
	text.Parent = ownerLabel

	placed[plotIndex][slotIndex] = {
		model = model,
		def = BrainrotDefs.get(defId),
		baseY = position.Y,
		phase = math.random() * math.pi * 2,
	}

	local pad = worldHandles.plots[plotIndex].pads[slotIndex]
	if pad then
		pad.ring.Color = BrainrotDefs.RarityColors[BrainrotDefs.get(defId).rarity] or Color3.fromRGB(200, 200, 200)
	end
end

function Bases.clearSlot(plotIndex: number, slotIndex: number)
	local entry = placed[plotIndex] and placed[plotIndex][slotIndex]
	if entry then
		entry.model:Destroy()
		placed[plotIndex][slotIndex] = nil
		local plot = worldHandles.plots[plotIndex]
		if plot and plot.pads[slotIndex] then
			plot.pads[slotIndex].ring.Color = Color3.fromRGB(90, 104, 128)
		end
	end
end

--- Re-renders a whole plot from a profile's slot table. Used on join and after
--- any change that moves several slots at once.
function Bases.renderPlot(plotIndex: number, slots: { [number]: any }, ownerName: string)
	for slotIndex = 1, Config.MaxSlots do
		local slot = slots[slotIndex]
		if slot then
			Bases.setSlot(plotIndex, slotIndex, slot.defId, slot.mutation, ownerName)
		else
			Bases.clearSlot(plotIndex, slotIndex)
		end
	end
end

function Bases.setLocked(plotIndex: number, locked: boolean)
	local plot = worldHandles.plots[plotIndex]
	if not plot then
		return
	end
	if not locked then
		if shields[plotIndex] then
			shields[plotIndex]:Destroy()
			shields[plotIndex] = nil
		end
		return
	end
	if shields[plotIndex] then
		return
	end
	local shield = Instance.new("Part")
	shield.Name = "BaseShield" .. plotIndex
	shield.Shape = Enum.PartType.Ball
	shield.Size = Vector3.new(Config.PlotSize + 6, Config.PlotSize * 0.78, Config.PlotSize + 6)
	shield.Position = plot.centre + Vector3.new(0, 12, 0)
	shield.Anchored = true
	shield.CanCollide = false
	shield.CanQuery = false
	shield.Material = Enum.Material.ForceField
	shield.Color = Color3.fromRGB(110, 226, 255)
	shield.Transparency = 0.42
	shield.Parent = displayFolder
	shields[plotIndex] = shield
end

--- Idle bob so bases feel alive: one Heartbeat for every placed brainrot.
function Bases.start()
	RunService.Heartbeat:Connect(function()
		local now = workspace:GetServerTimeNow()
		for plotIndex, slots in pairs(placed) do
			for slotIndex, entry in pairs(slots) do
				local position = Bases.slotPosition(plotIndex, slotIndex)
				if position then
					local bob = math.sin(now * 2.2 + entry.phase) * 0.22
					entry.model:PivotTo(
						CFrame.new(position + Vector3.new(0, 0.35 + bob, 0))
							* CFrame.Angles(0, now * 0.9 + entry.phase, 0)
					)
				end
			end
		end
	end)
end

function Bases.isHome(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	local plotIndex = Store.plotOwnerOf(player)
	if not plotIndex then
		return false
	end
	local centre = Bases.plotCentre(plotIndex)
	if not centre then
		return false
	end
	return (hrp.Position - centre).Magnitude <= Config.BaseRadius
end

function Bases.clearAll()
	for plotIndex = 1, Config.PlotCount do
		for slotIndex = 1, Config.MaxSlots do
			Bases.clearSlot(plotIndex, slotIndex)
		end
		Bases.setLocked(plotIndex, false)
	end
end

return Bases
