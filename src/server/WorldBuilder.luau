-- WorldBuilder: constructs the whole 3D map from code: conveyor runway, six
-- player plots with six slot pads each, the shop kiosk, spawn plaza, trees,
-- lamps and neon signs. Everything is anchored and non-collidable where it
-- would snag a character, so movement stays smooth on the 3D camera.
-- Returns a table of handles other modules need (slot pads, plot centres,
-- conveyor bounds), so nothing else has to search the workspace.

local Lighting = game:GetService("Lighting")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local WorldBuilder = {}

local PALETTE = {
	ground = Color3.fromRGB(88, 132, 66),
	path = Color3.fromRGB(196, 188, 168),
	conveyor = Color3.fromRGB(52, 56, 68),
	conveyorBelt = Color3.fromRGB(96, 104, 122),
	plot = Color3.fromRGB(120, 130, 152),
	slotPad = Color3.fromRGB(70, 80, 100),
	wood = Color3.fromRGB(112, 76, 46),
	leaf = Color3.fromRGB(58, 130, 62),
	neon = Color3.fromRGB(120, 226, 255),
	pink = Color3.fromRGB(255, 96, 176),
}

local function makePart(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		if key ~= "Parent" then
			(p :: any)[key] = value
		end
	end
	if props.Parent then
		p.Parent = props.Parent
	end
	return p
end

local function sign(parent: Instance, text: string, position: Vector3, size: Vector2, color: Color3, faceZ: number?)
	local holder = Instance.new("Part")
	holder.Name = "Sign"
	holder.Anchored = true
	holder.CanCollide = false
	holder.Size = Vector3.new(size.X / 10, size.Y / 10, 0.3)
	holder.Color = Color3.fromRGB(24, 26, 34)
	holder.Material = Enum.Material.SmoothPlastic
	holder.Position = position
	holder.Parent = parent

	local gui = Instance.new("SurfaceGui")
	gui.Face = faceZ and faceZ < 0 and Enum.NormalId.Back or Enum.NormalId.Front
	gui.CanvasSize = size
	gui.LightInfluence = 0
	gui.Parent = holder

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui

	local glow = Instance.new("PointLight")
	glow.Color = color
	glow.Range = 18
	glow.Brightness = 1.4
	glow.Parent = holder
	return holder
end

local function tree(parent: Instance, position: Vector3, scale: number)
	local trunk = makePart({
		Parent = parent,
		Name = "TreeTrunk",
		Size = Vector3.new(2, 9 * scale, 2),
		Color = PALETTE.wood,
		Material = Enum.Material.Wood,
		Position = position + Vector3.new(0, 4.5 * scale, 0),
	})
	local leaves = makePart({
		Parent = parent,
		Name = "TreeCrown",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(9, 9, 9) * scale,
		Color = PALETTE.leaf,
		Material = Enum.Material.Grass,
		Position = trunk.Position + Vector3.new(0, 5.6 * scale, 0),
	})
	leaves.CanCollide = false
end

local function lamp(parent: Instance, position: Vector3)
	local pole = makePart({
		Parent = parent,
		Name = "LampPole",
		Size = Vector3.new(0.6, 14, 0.6),
		Color = Color3.fromRGB(60, 64, 76),
		Material = Enum.Material.Metal,
		Position = position + Vector3.new(0, 7, 0),
	})
	local bulb = makePart({
		Parent = parent,
		Name = "LampBulb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.2, 2.2, 2.2),
		Color = PALETTE.neon,
		Material = Enum.Material.Neon,
		Position = pole.Position + Vector3.new(0, 7.6, 0),
	})
	bulb.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = PALETTE.neon
	light.Range = 34
	light.Brightness = 2
	light.Parent = bulb
end

local function buildConveyor(parent: Instance, handles: any)
	local length = Config.ConveyorEndX - Config.ConveyorStartX
	local midX = (Config.ConveyorStartX + Config.ConveyorEndX) / 2
	makePart({
		Parent = parent,
		Name = "ConveyorDeck",
		Size = Vector3.new(length, 0.8, 10),
		Color = PALETTE.conveyor,
		Material = Enum.Material.Metal,
		Position = Vector3.new(midX, Config.ConveyorHeight - 0.4, Config.ConveyorZ),
	})
	local belt = makePart({
		Parent = parent,
		Name = "ConveyorBelt",
		Size = Vector3.new(length, 0.2, 8.6),
		Color = PALETTE.conveyorBelt,
		Material = Enum.Material.DiamondPlate,
		Position = Vector3.new(midX, Config.ConveyorHeight, Config.ConveyorZ),
	})
	belt.CanCollide = false

	for x = Config.ConveyorStartX, Config.ConveyorEndX, 8 do
		makePart({
			Parent = parent,
			Name = "ConveyorStripe",
			Size = Vector3.new(1.2, 0.06, 8.4),
			Color = Color3.fromRGB(230, 200, 60),
			Material = Enum.Material.Neon,
			Position = Vector3.new(x, Config.ConveyorHeight + 0.06, Config.ConveyorZ),
			CanCollide = false,
		})
	end

	for _, x in ipairs({ Config.ConveyorStartX, Config.ConveyorEndX }) do
		makePart({
			Parent = parent,
			Name = "ConveyorRail",
			Size = Vector3.new(1.2, 3.4, 10.6),
			Color = Color3.fromRGB(40, 44, 56),
			Material = Enum.Material.Metal,
			Position = Vector3.new(x, Config.ConveyorHeight + 1.4, Config.ConveyorZ),
			CanCollide = false,
		})
	end

	sign(parent, "BRAINROT CONVEYOR", Vector3.new(midX, Config.ConveyorHeight + 8, Config.ConveyorZ - 6), Vector2.new(700, 110), PALETTE.neon)
	handles.conveyorY = Config.ConveyorHeight
end

local function buildPlot(parent: Instance, plotIndex: number, handles: any)
	local centre = Config.PlotPositions[plotIndex]
	local size = Config.PlotSize

	local pad = makePart({
		Parent = parent,
		Name = "Plot" .. plotIndex,
		Size = Vector3.new(size, 1, size),
		Color = PALETTE.plot,
		Material = Enum.Material.Slate,
		Position = centre + Vector3.new(0, 0.5, 0),
	})
	pad.CanCollide = true

	local trim = makePart({
		Parent = parent,
		Name = "PlotTrim" .. plotIndex,
		Size = Vector3.new(size + 1.2, 0.5, size + 1.2),
		Color = PALETTE.neon,
		Material = Enum.Material.Neon,
		Position = centre + Vector3.new(0, 0.2, 0),
		CanCollide = false,
	})
	trim.CanQuery = false

	local pads = {}
	for slotIndex, offset in ipairs(Config.SlotOffsets) do
		local slotPad = makePart({
			Parent = parent,
			Name = ("Plot%dSlot%d"):format(plotIndex, slotIndex),
			Size = Vector3.new(8.4, 0.35, 8.4),
			Color = PALETTE.slotPad,
			Material = Enum.Material.SmoothPlastic,
			Position = centre + offset + Vector3.new(0, 1.1, 0),
			CanCollide = false,
		})
		local ring = makePart({
			Parent = parent,
			Name = ("Plot%dSlotRing%d"):format(plotIndex, slotIndex),
			Size = Vector3.new(9.2, 0.12, 9.2),
			Color = Color3.fromRGB(90, 104, 128),
			Material = Enum.Material.Neon,
			Position = centre + offset + Vector3.new(0, 1.32, 0),
			CanCollide = false,
		})
		ring.CanQuery = false
		pads[slotIndex] = {
			part = slotPad,
			ring = ring,
			position = centre + offset + Vector3.new(0, 1.4, 0),
		}
	end
	handles.plots[plotIndex] = { centre = centre, pads = pads, pad = pad, trim = trim }
end

function WorldBuilder.build(): any
	local root = Instance.new("Folder")
	root.Name = "BrainrotWorld"
	root.Parent = workspace

	local handles = { plots = {}, conveyorY = Config.ConveyorHeight }

	-- Ground planes: a big grass field already exists, add paths and plazas.
	makePart({
		Parent = root,
		Name = "Plaza",
		Size = Vector3.new(210, 1, 46),
		Color = PALETTE.path,
		Material = Enum.Material.Cobblestone,
		Position = Vector3.new(0, 0.5, 0),
	})

	makePart({
		Parent = root,
		Name = "ShopPlaza",
		Size = Vector3.new(64, 1, 46),
		Color = PALETTE.path,
		Material = Enum.Material.Cobblestone,
		Position = Vector3.new(0, 0.5, 74),
	})

	for laneIndex, z in ipairs({ -26, 26 }) do
		makePart({
			Parent = root,
			Name = "Walkway" .. laneIndex,
			Size = Vector3.new(230, 1, 10),
			Color = Color3.fromRGB(170, 162, 146),
			Material = Enum.Material.Cobblestone,
			Position = Vector3.new(0, 0.5, z),
		})
	end

	buildConveyor(root, handles)

	for plotIndex = 1, Config.PlotCount do
		buildPlot(root, plotIndex, handles)
	end

	-- Shop kiosk with a roof, counter and neon sign.
	local shop = Instance.new("Model")
	shop.Name = "Shop"
	shop.Parent = root
	local shopPos = Config.ShopPosition
	makePart({
		Parent = shop,
		Name = "ShopFloor",
		Size = Vector3.new(44, 1, 30),
		Color = Color3.fromRGB(96, 74, 58),
		Material = Enum.Material.WoodPlanks,
		Position = shopPos + Vector3.new(0, 0.5, 0),
	})
	makePart({
		Parent = shop,
		Name = "ShopCounter",
		Size = Vector3.new(40, 5, 3),
		Color = Color3.fromRGB(150, 108, 70),
		Material = Enum.Material.Wood,
		Position = shopPos + Vector3.new(0, 3, 12),
	})
	for _, x in ipairs({ -19, 19 }) do
		makePart({
			Parent = shop,
			Name = "ShopPillar",
			Size = Vector3.new(2, 18, 2),
			Color = Color3.fromRGB(214, 206, 190),
			Material = Enum.Material.Concrete,
			Position = shopPos + Vector3.new(x, 9, 14),
		})
	end
	makePart({
		Parent = shop,
		Name = "ShopRoof",
		Size = Vector3.new(46, 1.4, 20),
		Color = Color3.fromRGB(72, 90, 140),
		Material = Enum.Material.Metal,
		Position = shopPos + Vector3.new(0, 18, 6),
	})
	sign(shop, "BRAINROT SHOP", shopPos + Vector3.new(0, 22, 14), Vector2.new(760, 120), PALETTE.pink)

	for _, x in ipairs({ -44, -22, 22, 44 }) do
		sign(root, (x < 0 and "STEAL RISK" or "LOCK YOUR BASE"), Vector3.new(x, 9, 68), Vector2.new(420, 90), x < 0 and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(140, 255, 180))
	end

	-- Trees, lamps and neon signs around the rim.
	for _, pos in ipairs({
		Vector3.new(-92, 0, -86), Vector3.new(-46, 0, -92), Vector3.new(46, 0, -92), Vector3.new(92, 0, -86),
		Vector3.new(-92, 0, 86), Vector3.new(-46, 0, 94), Vector3.new(46, 0, 94), Vector3.new(92, 0, 90),
		Vector3.new(-120, 0, 0), Vector3.new(120, 0, 0), Vector3.new(-120, 0, -46), Vector3.new(120, 0, 46),
	}) do
		tree(root, pos, 1 + (pos.X % 3) * 0.12)
	end

	for _, pos in ipairs({
		Vector3.new(-30, 0, -70), Vector3.new(30, 0, -70),
		Vector3.new(-30, 0, 66), Vector3.new(30, 0, 66),
		Vector3.new(-104, 0, 22), Vector3.new(104, 0, -22),
	}) do
		lamp(root, pos)
	end

	sign(root, Config.GameName, Vector3.new(0, 26, -78), Vector2.new(900, 150), PALETTE.pink)
	sign(root, "GRAB · RUN · STACK · GET RICH", Vector3.new(0, 18, -78), Vector2.new(760, 80), PALETTE.neon)

	-- Spawn plaza marker.
	local spawnPad = makePart({
		Parent = root,
		Name = "SpawnPad",
		Size = Vector3.new(30, 0.6, 30),
		Color = Color3.fromRGB(86, 200, 226),
		Material = Enum.Material.Neon,
		Position = Config.SpawnPosition - Vector3.new(0, 2.7, 0),
		CanCollide = false,
	})
	spawnPad.CanQuery = false
	local spawnLight = Instance.new("PointLight")
	spawnLight.Color = PALETTE.neon
	spawnLight.Range = 40
	spawnLight.Brightness = 1.5
	spawnLight.Parent = spawnPad

	local existing = workspace:FindFirstChildOfClass("SpawnLocation")
	if not existing then
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "PlayerSpawn"
		spawn.Size = Vector3.new(14, 1, 14)
		spawn.Position = Config.SpawnPosition - Vector3.new(0, 2, 0)
		spawn.Anchored = true
		spawn.Transparency = 1
		spawn.CanCollide = false
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Parent = workspace
	end

	Lighting.ClockTime = 15.5
	Lighting.FogEnd = 700
	Lighting.FogColor = Color3.fromRGB(186, 214, 236)

	return handles
end

return WorldBuilder
