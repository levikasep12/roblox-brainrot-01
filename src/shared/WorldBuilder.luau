-- Builds the whole 3D map in code: ground, conveyor runway, six base plots,
-- the shop, the rebirth altar, lamps, trees and fences. Runs once on the server.

local PlotLayout = require(script.Parent.PlotLayout)

local WorldBuilder = {}

local PALETTE = {
	grass = Color3.fromRGB(84, 134, 96),
	grassDark = Color3.fromRGB(70, 116, 82),
	path = Color3.fromRGB(172, 166, 150),
	pathDark = Color3.fromRGB(142, 136, 122),
	belt = Color3.fromRGB(44, 46, 58),
	beltEdge = Color3.fromRGB(96, 102, 122),
	metal = Color3.fromRGB(140, 148, 164),
	wood = Color3.fromRGB(126, 90, 58),
	leaf = Color3.fromRGB(72, 150, 92),
	leafDark = Color3.fromRGB(56, 122, 76),
	trunk = Color3.fromRGB(104, 74, 48),
	pink = Color3.fromRGB(255, 112, 158),
	cyan = Color3.fromRGB(96, 224, 240),
	purple = Color3.fromRGB(148, 108, 236),
	gold = Color3.fromRGB(250, 202, 74),
	white = Color3.fromRGB(242, 244, 250),
}

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, options: any?): Part
	options = options or {}
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = cframe
	object.Color = color
	object.Anchored = true
	object.Material = options.material or Enum.Material.SmoothPlastic
	object.Transparency = options.transparency or 0
	object.CanCollide = options.canCollide ~= false
	object.CanQuery = options.canQuery ~= false
	object.CanTouch = options.canTouch ~= false
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Shape = options.shape or Enum.PartType.Block
	object.Parent = parent
	return object
end

local function folder(parent: Instance, name: string): Folder
	local object = Instance.new("Folder")
	object.Name = name
	object.Parent = parent
	return object
end

local function model(parent: Instance, name: string): Model
	local object = Instance.new("Model")
	object.Name = name
	object.Parent = parent
	return object
end

local function textSign(parent: Instance, name: string, size: Vector2, text: string, color: Color3, position: CFrame, textColor: Color3?)
	local board = part(parent, name, Vector3.new(size.X, size.Y, 0.4), position, color, { material = Enum.Material.SmoothPlastic })
	for index, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local surface = Instance.new("SurfaceGui")
		surface.Name = if index == 1 then "Face" else "FaceBack"
		surface.Face = face
		surface.CanvasSize = size
		surface.LightInfluence = 0
		surface.Parent = board
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.Text = text
		label.TextColor3 = textColor or Color3.fromRGB(252, 250, 244)
		label.TextScaled = true
		label.TextWrapped = true
		label.Parent = surface
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.PaddingTop = UDim.new(0, 6)
		padding.PaddingBottom = UDim.new(0, 6)
		padding.Parent = label
	end
	return board
end

local function neonStrip(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3)
	return part(parent, name, size, cframe, color, { material = Enum.Material.Neon })
end

local function buildGround(root: Folder)
	local ground = model(root, "Ground")
	part(
		ground,
		"Grass",
		Vector3.new(360, 4, 300),
		CFrame.new(0, -2, 0),
		PALETTE.grass,
		{ material = Enum.Material.Grass }
	)

	local plaza = part(ground, "Plaza", Vector3.new(56, 0.4, 26), CFrame.new(0, 0.2, 0), PALETTE.path, { material = Enum.Material.Slate })
	plaza.Name = "BeltPlaza"

	for side = -1, 1, 2 do
		part(ground, "PlayerPath", Vector3.new(196, 0.3, 7), CFrame.new(0, 0.16, 22.5 * side), PALETTE.pathDark, { material = Enum.Material.Slate })
	end
	for _, plot in ipairs(PlotLayout.Plots) do
		part(
			ground,
			"PlotApproach",
			Vector3.new(10, 0.3, 18),
			CFrame.new(plot.center.X, 0.16, plot.center.Z + plot.facing * 20),
			PALETTE.path,
			{ material = Enum.Material.Slate }
		)
	end

	local function pad(name: string, size: Vector3, position: Vector3)
		part(ground, name, size, CFrame.new(position), PALETTE.pathDark, { material = Enum.Material.Slate })
	end

	pad("ShopLane", Vector3.new(34, 0.3, 9), Vector3.new(99, 0.16, 0))
	pad("ShopConnector", Vector3.new(9, 0.3, 24), Vector3.new(90, 0.16, 12))
	pad("AltarLane", Vector3.new(30, 0.3, 9), Vector3.new(-97, 0.16, 0))
	pad("AltarConnector", Vector3.new(9, 0.3, 24), Vector3.new(-90, 0.16, 12))

	for i = -4, 4 do
		for j = -2, 2 do
			if (i + j) % 2 == 0 then
				local tile = part(
					ground,
					"PlazaTile",
					Vector3.new(5.6, 0.06, 5.6),
					CFrame.new(i * 6.2, 0.45, j * 6.2),
					if (i * 3 + j) % 4 == 0 then Color3.fromRGB(160, 156, 142) else Color3.fromRGB(184, 178, 162),
					{ material = Enum.Material.Slate, canCollide = false, canQuery = false, canTouch = false }
				)
				tile.Name = "PlazaTile"
			end
		end
	end
end

local function buildConveyor(root: Folder)
	local conveyor = model(root, "Conveyor")
	local startX = -80
	local endX = 84
	local length = endX - startX
	local centerX = (startX + endX) / 2

	local belt = part(
		conveyor,
		"Belt",
		Vector3.new(length, 1.0, 16),
		CFrame.new(centerX, 1.1, 0),
		PALETTE.belt,
		{ material = Enum.Material.DiamondPlate }
	)
	belt:SetAttribute("WalkSpeed", 0)

	part(conveyor, "BeltGlow", Vector3.new(length, 0.12, 1.2), CFrame.new(centerX, 1.66, 0), PALETTE.cyan, { material = Enum.Material.Neon, canCollide = false })

	for _, side in ipairs({ -1, 1 }) do
		part(conveyor, "Rail", Vector3.new(length, 0.7, 0.6), CFrame.new(centerX, 1.85, 7.7 * side), PALETTE.beltEdge, { material = Enum.Material.Metal })
		part(conveyor, "RailGlow", Vector3.new(length, 0.16, 0.2), CFrame.new(centerX, 2.24, 7.7 * side), PALETTE.pink, { material = Enum.Material.Neon, canCollide = false })
	end

	for x = startX + 8, endX - 8, 16 do
		for _, side in ipairs({ -1, 1 }) do
			part(conveyor, "Leg", Vector3.new(1.2, 1.2, 1.2), CFrame.new(x, 0.6, 6.2 * side), PALETTE.metal, { material = Enum.Material.Metal })
		end
	end

	for i = 0, 19 do
		local x = startX + 8 + i * 8
		local stripe = part(
			conveyor,
			"Chevron",
			Vector3.new(3.4, 0.08, 14.4),
			CFrame.new(x, 1.62, 0),
			Color3.fromRGB(84, 88, 108),
			{ material = Enum.Material.SmoothPlastic, canCollide = false, canQuery = false, canTouch = false }
		)
		stripe.CFrame = CFrame.new(x, 1.62, 0) * CFrame.Angles(0, math.rad(18), 0)
	end

	local arch = model(conveyor, "SpawnArch")
	for _, side in ipairs({ -1, 1 }) do
		part(arch, "ArchPillar", Vector3.new(1.6, 18, 1.6), CFrame.new(startX + 2, 9, 9.4 * side), PALETTE.beltEdge, { material = Enum.Material.Metal })
	end
	neonStrip(arch, "ArchBar", Vector3.new(2.4, 1.2, 20.6), CFrame.new(startX + 2, 18.6, 0), PALETTE.cyan)
	textSign(arch, "ArchSign", Vector2.new(20, 5), "BRAINROT BELT", Color3.fromRGB(22, 24, 34), CFrame.new(startX + 2, 18.6, 0) * CFrame.Angles(0, math.rad(90), 0), PALETTE.cyan)

	local gate = model(conveyor, "ExitGate")
	for _, side in ipairs({ -1, 1 }) do
		part(gate, "GatePost", Vector3.new(1.4, 12, 1.4), CFrame.new(endX, 6, 9 * side), PALETTE.beltEdge, { material = Enum.Material.Metal })
	end
	neonStrip(gate, "GateBar", Vector3.new(2.0, 0.9, 19), CFrame.new(endX, 12.4, 0), PALETTE.pink)
	textSign(gate, "GateSign", Vector2.new(18, 4), "GRAB OR MISS", Color3.fromRGB(24, 22, 32), CFrame.new(endX, 12.4, 0) * CFrame.Angles(0, math.rad(-90), 0), PALETTE.pink)

	for _, x in ipairs({ startX + 40, centerX, endX - 34 }) do
		local post = part(conveyor, "ConveyorLamp", Vector3.new(0.5, 10, 0.5), CFrame.new(x, 5, 10.4), PALETTE.metal, { material = Enum.Material.Metal })
		post.Name = "ConveyorLampPost"
		neonStrip(conveyor, "ConveyorLampGlow", Vector3.new(1.4, 0.6, 1.4), CFrame.new(x, 10.2, 10.4), PALETTE.gold)
	end

	return conveyor
end

local function buildPlot(parent: Folder, plot)
	local plotModel = model(parent, plot.name)
	plotModel:SetAttribute("PlotIndex", plot.index)
	plotModel:SetAttribute("PlotKind", plot.kind)

	local isRival = plot.kind == "rival"
	local floorColor = if isRival then Color3.fromRGB(96, 76, 104) else Color3.fromRGB(70, 96, 138)
	local trimColor = if isRival then Color3.fromRGB(186, 128, 208) else Color3.fromRGB(104, 184, 236)
	local center = plot.center
	local facing = plot.facing or 1
	local backZ = center.Z - facing * 13.6
	local entranceZ = center.Z + facing * 12.2
	local signRotation = if facing == 1 then math.pi else 0

	part(plotModel, "Floor", Vector3.new(38, 1.2, 28), CFrame.new(center + Vector3.new(0, 0.6, 0)), floorColor, { material = Enum.Material.Slate })
	part(plotModel, "FloorTrim", Vector3.new(38.6, 0.3, 28.6), CFrame.new(center + Vector3.new(0, 1.2, 0)), trimColor, { material = Enum.Material.Neon, canCollide = false })
	part(plotModel, "BackWall", Vector3.new(38, 9, 1.2), CFrame.new(center.X, 5.7, backZ), if isRival then Color3.fromRGB(76, 60, 86) else Color3.fromRGB(58, 78, 112), { material = Enum.Material.Brick })

	for side = -1, 1, 2 do
		part(plotModel, "SideRail", Vector3.new(1.0, 3.2, 27), CFrame.new(center.X + 18.6 * side, 2.8, center.Z), PALETTE.beltEdge, { material = Enum.Material.Metal })
	end

	local slotIndex = 0
	for _, offset in ipairs(PlotLayout.SlotOffsets) do
		slotIndex += 1
		local padPosition = center + Vector3.new(offset.X * facing, 1.4, offset.Z)
		local pad = part(
			plotModel,
			"SlotPad" .. slotIndex,
			Vector3.new(0.35, 6.6, 6.6),
			CFrame.new(padPosition) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(52, 56, 68),
			{ material = Enum.Material.Metal, shape = Enum.PartType.Cylinder }
		)
		pad:SetAttribute("SlotPad", true)
		pad:SetAttribute("SlotIndex", slotIndex)

		local ring = neonStrip(
			plotModel,
			"SlotRing" .. slotIndex,
			Vector3.new(0.35, 7.2, 7.2),
			CFrame.new(padPosition + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			trimColor
		)
		ring.CanQuery = false
		ring.CanTouch = false
		ring:SetAttribute("SlotRing", true)
		ring:SetAttribute("SlotIndex", slotIndex)
	end

	local signBoard = textSign(
		plotModel,
		"OwnerSign",
		Vector2.new(26, 6),
		if isRival then "RIVAL BASE" else "PLOT " .. plot.index,
		Color3.fromRGB(18, 20, 28),
		CFrame.new(center.X, 9.2, backZ + facing * 0.9) * CFrame.Angles(0, signRotation, 0),
		trimColor
	)
	signBoard.CanCollide = true

	local barrier = part(
		plotModel,
		"LockBarrier",
		Vector3.new(37, 8, 0.3),
		CFrame.new(center.X, 5, entranceZ),
		trimColor,
		{ material = Enum.Material.ForceField, transparency = 1, canCollide = false }
	)
	barrier.Name = "LockBarrier"

	return plotModel
end

local function buildPlots(root: Folder)
	local plots = folder(root, "Plots")
	for _, plot in ipairs(PlotLayout.Plots) do
		buildPlot(plots, plot)
	end
	return plots
end

local function buildShop(root: Folder)
	local shop = model(root, "Shop")
	local center = Vector3.new(110, 0, 0)

	part(shop, "ShopFloor", Vector3.new(30, 0.6, 34), CFrame.new(center + Vector3.new(0, 0.3, 0)), Color3.fromRGB(66, 72, 92), { material = Enum.Material.Slate })
	neonStrip(shop, "ShopFloorTrim", Vector3.new(31, 0.22, 35), CFrame.new(center + Vector3.new(0, 0.66, 0)), PALETTE.gold)

	for _, offset in ipairs({ Vector3.new(0, 0, -15), Vector3.new(0, 0, 15) }) do
		part(shop, "ShopPillar", Vector3.new(1.4, 15, 1.4), CFrame.new(center + offset + Vector3.new(-13, 7.5, 0)), PALETTE.beltEdge, { material = Enum.Material.Metal })
		part(shop, "ShopPillar", Vector3.new(1.4, 15, 1.4), CFrame.new(center + offset + Vector3.new(13, 7.5, 0)), PALETTE.beltEdge, { material = Enum.Material.Metal })
	end

	part(shop, "ShopCanopy", Vector3.new(30, 1.2, 34), CFrame.new(center + Vector3.new(0, 15.2, 0)), Color3.fromRGB(232, 214, 172), { material = Enum.Material.Fabric })
	part(shop, "ShopCanopyStripe", Vector3.new(30.4, 1.3, 6), CFrame.new(center + Vector3.new(0, 15.2, -8)), PALETTE.pink, { material = Enum.Material.Fabric })
	part(shop, "ShopCanopyStripe", Vector3.new(30.4, 1.3, 6), CFrame.new(center + Vector3.new(0, 15.2, 8)), PALETTE.cyan, { material = Enum.Material.Fabric })

	local sign = textSign(shop, "ShopSign", Vector2.new(28, 6), "BRAINROT EMPORIUM", Color3.fromRGB(22, 22, 32), CFrame.new(center + Vector3.new(0, 15.3, -17)) * CFrame.Angles(0, math.pi, 0), PALETTE.gold)
	sign.CanCollide = false

	part(shop, "ShopCounter", Vector3.new(18, 3, 6), CFrame.new(center + Vector3.new(0, 2.1, 4)), PALETTE.wood, { material = Enum.Material.Wood })
	part(shop, "ShopCounterTop", Vector3.new(18.8, 0.4, 6.8), CFrame.new(center + Vector3.new(0, 3.8, 4)), Color3.fromRGB(196, 154, 108), { material = Enum.Material.Wood })
	neonStrip(shop, "CounterGlow", Vector3.new(18.8, 0.12, 0.3), CFrame.new(center + Vector3.new(0, 3.6, 7.35)), PALETTE.cyan)

	for index, offset in ipairs({ Vector3.new(-10, 0, -8), Vector3.new(0, 0, -8), Vector3.new(10, 0, -8) }) do
		local pedestal = part(shop, "DisplayPedestal" .. index, Vector3.new(4.4, 2.4, 4.4), CFrame.new(center + offset + Vector3.new(0, 1.2, 0)), Color3.fromRGB(56, 60, 80), { material = Enum.Material.Marble })
		pedestal.Name = "DisplayPedestal" .. index
		neonStrip(shop, "PedestalRing", Vector3.new(4.8, 0.2, 4.8), CFrame.new(center + offset + Vector3.new(0, 2.45, 0)), PALETTE.purple)
	end

	part(shop, "ShopSignPost", Vector3.new(0.7, 9, 0.7), CFrame.new(center + Vector3.new(17, 4.5, -16)), PALETTE.metal, { material = Enum.Material.Metal })
	textSign(shop, "ShopPointer", Vector2.new(8, 3), "SHOP", Color3.fromRGB(24, 22, 32), CFrame.new(center + Vector3.new(17, 9.5, -16)) * CFrame.Angles(0, math.pi, 0), PALETTE.gold)

	return shop
end

local function buildRebirthAltar(root: Folder)
	local altar = model(root, "RebirthAltar")
	local center = Vector3.new(-110, 0, 0)

	part(altar, "AltarBase", Vector3.new(20, 1.4, 20), CFrame.new(center + Vector3.new(0, 0.7, 0)), Color3.fromRGB(62, 54, 92), { material = Enum.Material.Marble })
	part(altar, "AltarStep", Vector3.new(16, 1.2, 16), CFrame.new(center + Vector3.new(0, 1.6, 0)), Color3.fromRGB(82, 70, 118), { material = Enum.Material.Marble })
	neonStrip(altar, "AltarRing", Vector3.new(17, 0.18, 17), CFrame.new(center + Vector3.new(0, 2.2, 0)), PALETTE.purple)
	part(altar, "AltarPedestal", Vector3.new(5, 6, 5), CFrame.new(center + Vector3.new(0, 5.2, 0)), Color3.fromRGB(46, 40, 70), { material = Enum.Material.Marble })
	for i = 0, 3 do
		local angle = i / 4 * math.pi * 2
		part(altar, "AltarPillar", Vector3.new(1.4, 11, 1.4), CFrame.new(center + Vector3.new(math.cos(angle) * 7.4, 6.8, math.sin(angle) * 7.4)), Color3.fromRGB(110, 96, 156), { material = Enum.Material.Marble })
		neonStrip(altar, "PillarGlow", Vector3.new(1.6, 0.5, 1.6), CFrame.new(center + Vector3.new(math.cos(angle) * 7.4, 12.4, math.sin(angle) * 7.4)), PALETTE.purple)
	end
	neonStrip(altar, "AltarOrb", Vector3.new(4.4, 4.4, 4.4), CFrame.new(center + Vector3.new(0, 10.4, 0)), PALETTE.cyan, { shape = Enum.PartType.Ball })
	local orb = altar:FindFirstChild("AltarOrb")
	if orb then
		orb.Shape = Enum.PartType.Ball
		orb.Name = "RebirthOrb"
		local light = Instance.new("PointLight")
		light.Color = PALETTE.cyan
		light.Brightness = 2
		light.Range = 26
		light.Parent = orb
	end

	textSign(altar, "AltarSign", Vector2.new(16, 4), "REBIRTH ALTAR", Color3.fromRGB(18, 18, 26), CFrame.new(center + Vector3.new(0, 14.2, -8.4)), PALETTE.cyan)
	return altar
end

local function buildTree(parent: Instance, position: Vector3, scale: number)
	local tree = model(parent, "Tree")
	part(tree, "Trunk", Vector3.new(2.0 * scale, 9 * scale, 2.0 * scale), CFrame.new(position + Vector3.new(0, 4.5 * scale, 0)), PALETTE.trunk, { material = Enum.Material.Wood })
	part(tree, "Leaves", Vector3.new(11 * scale, 9 * scale, 11 * scale), CFrame.new(position + Vector3.new(0, 10.5 * scale, 0)), PALETTE.leaf, { material = Enum.Material.Grass, shape = Enum.PartType.Ball })
	part(tree, "LeavesTop", Vector3.new(7 * scale, 7 * scale, 7 * scale), CFrame.new(position + Vector3.new(0, 14.5 * scale, 0)), PALETTE.leafDark, { material = Enum.Material.Grass, shape = Enum.PartType.Ball })
	return tree
end

local function buildLamp(parent: Instance, position: Vector3)
	local lamp = model(parent, "Lamp")
	part(lamp, "Pole", Vector3.new(0.7, 12, 0.7), CFrame.new(position + Vector3.new(0, 6, 0)), PALETTE.metal, { material = Enum.Material.Metal })
	part(lamp, "Arm", Vector3.new(4, 0.5, 0.5), CFrame.new(position + Vector3.new(1.8, 12, 0)), PALETTE.metal, { material = Enum.Material.Metal })
	local bulb = neonStrip(lamp, "Bulb", Vector3.new(1.6, 1.2, 1.6), CFrame.new(position + Vector3.new(3.4, 11.6, 0)), PALETTE.gold)
	bulb.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 150)
	light.Brightness = 1.4
	light.Range = 22
	light.Parent = bulb
	return lamp
end

local function buildDecor(root: Folder)
	local decor = folder(root, "Decor")

	for index, position in ipairs({
		Vector3.new(-130, 0, -90),
		Vector3.new(-74, 0, -98),
		Vector3.new(-16, 0, -104),
		Vector3.new(46, 0, -96),
		Vector3.new(112, 0, -104),
		Vector3.new(142, 0, -62),
		Vector3.new(146, 0, 62),
		Vector3.new(112, 0, 104),
		Vector3.new(48, 0, 96),
		Vector3.new(-18, 0, 108),
		Vector3.new(-82, 0, 102),
		Vector3.new(-138, 0, 86),
		Vector3.new(-146, 0, -16),
		Vector3.new(-132, 0, -58),
	}) do
		buildTree(decor, position, 0.85 + (index % 4) * 0.12)
	end

	for _, position in ipairs({
		Vector3.new(-34, 0, 13),
		Vector3.new(34, 0, 13),
		Vector3.new(-34, 0, -13),
		Vector3.new(34, 0, -13),
		Vector3.new(86, 0, 18),
		Vector3.new(-108, 0, 22),
	}) do
		buildLamp(decor, position)
	end

	for i = -4, 4 do
		if i ~= 0 then
			local x = i * 22
			part(decor, "Fence", Vector3.new(0.6, 5, 0.6), CFrame.new(x, 2.5, -118), PALETTE.wood, { material = Enum.Material.Wood })
			part(decor, "FenceRail", Vector3.new(22, 0.5, 0.4), CFrame.new(x - 11, 4.2, -118), PALETTE.wood, { material = Enum.Material.Wood })
			part(decor, "Fence", Vector3.new(0.6, 5, 0.6), CFrame.new(x, 2.5, 118), PALETTE.wood, { material = Enum.Material.Wood })
		end
	end

	for i = 1, 18 do
		local angle = i / 18 * math.pi * 2
		local bush = part(
			decor,
			"Bush",
			Vector3.new(3.4, 2.2, 3.4),
			CFrame.new(math.cos(angle) * 132, 1, math.sin(angle) * 108),
			if i % 2 == 0 then PALETTE.leafDark else PALETTE.leaf,
			{ material = Enum.Material.Grass, shape = Enum.PartType.Ball }
		)
		bush.Name = "Bush"
	end

	local balloons = model(decor, "Balloons")
	for i = 0, 5 do
		local angle = i / 6 * math.pi * 2
		local balloon = neonStrip(
			balloons,
			"Balloon",
			Vector3.new(2.6, 3.4, 2.6),
			CFrame.new(-110 + math.cos(angle) * 12, 18 + (i % 3), 0 + math.sin(angle) * 12),
			if i % 3 == 0 then PALETTE.pink elseif i % 3 == 1 then PALETTE.cyan else PALETTE.gold
		)
		balloon.Shape = Enum.PartType.Ball
		balloon.CanCollide = false
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(12, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.55, -20)
	spawn.Anchored = true
	spawn.Color = PALETTE.pink
	spawn.Material = Enum.Material.Neon
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = decor

	neonStrip(decor, "SpawnPadRing", Vector3.new(13, 0.3, 9), CFrame.new(0, 1.02, -20), PALETTE.pink)

	local gate = model(decor, "WelcomeGate")
	for _, side in ipairs({ -1, 1 }) do
		part(gate, "GatePost", Vector3.new(1.6, 15, 1.6), CFrame.new(20 * side, 7.5, -13), PALETTE.beltEdge, { material = Enum.Material.Metal })
		neonStrip(gate, "GatePostGlow", Vector3.new(1.9, 0.6, 1.9), CFrame.new(20 * side, 15.2, -13), PALETTE.pink)
	end
	textSign(gate, "WelcomeSign", Vector2.new(40, 6), "BRAINROT RUSH", Color3.fromRGB(20, 20, 32), CFrame.new(0, 12.6, -13), PALETTE.cyan)
	neonStrip(gate, "WelcomeGlow", Vector3.new(41, 0.4, 0.6), CFrame.new(0, 9.4, -13), PALETTE.pink)

	return decor
end

function WorldBuilder.build(root: Folder)
	buildGround(root)
	buildConveyor(root)
	buildPlots(root)
	buildShop(root)
	buildRebirthAltar(root)
	buildDecor(root)
	return root
end

return WorldBuilder
