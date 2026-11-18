-- Builds the whole 3D world in code: a large baseplate, a raised conveyor
-- runway down the middle, six base plots with slot pads and fences, a shop
-- building, a rebirth altar, trees, lamps, signs and a spawn plaza. No
-- uploaded assets: every prop is parts.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local WorldBuilder = {}

local PALETTE = {
	grass = Color3.fromRGB(96, 176, 112),
	grassDark = Color3.fromRGB(78, 152, 96),
	path = Color3.fromRGB(198, 190, 168),
	pathDark = Color3.fromRGB(172, 164, 144),
	metal = Color3.fromRGB(92, 100, 116),
	metalDark = Color3.fromRGB(62, 68, 82),
	wood = Color3.fromRGB(146, 104, 68),
	woodDark = Color3.fromRGB(112, 78, 50),
	leaf = Color3.fromRGB(62, 148, 92),
	leafLight = Color3.fromRGB(88, 178, 104),
	stone = Color3.fromRGB(140, 140, 152),
	white = Color3.fromRGB(242, 244, 248),
	neon = Color3.fromRGB(96, 240, 255),
	pink = Color3.fromRGB(255, 106, 168),
}

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Color = props.color or PALETTE.stone
	p.Size = props.size or Vector3.new(4, 1, 4)
	p.CFrame = props.cframe or CFrame.new(props.position or Vector3.zero)
	p.Name = props.name or "Part"
	if props.transparency then
		p.Transparency = props.transparency
	end
	if props.shape then
		p.Shape = props.shape
	end
	if props.reflectance then
		p.Reflectance = props.reflectance
	end
	p.Parent = props.parent
	return p
end

-- A cylinder written (diameter, height, diameter), like a normal part where Y
-- is up. A Part's cylinder axis runs along its own X, so the part is given
-- Size (height, diameter, diameter) and turned 90 degrees to stand upright.
-- `lay` (degrees about Z, applied before the upright turn) lays it down.
local function cylinder(props)
	props.shape = Enum.PartType.Cylinder
	local size = props.size
	props.size = Vector3.new(size.Y, size.X, size.Z)
	local lay = props.lay or 0
	props.lay = nil
	local created = part(props)
	created.CFrame = created.CFrame * CFrame.Angles(0, 0, math.rad(90 + lay))
	return created
end

local function textLabel(parent, text, color, size)
	local surface = Instance.new("SurfaceGui")
	surface.Name = "Sign"
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 42
	surface.LightInfluence = 0
	surface.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.Text = text
	label.Parent = surface

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(10, 10, 16)
	stroke.Thickness = 2
	stroke.Parent = label
	return surface
end

local function billboardSign(position, text, color, width)
	local anchor = Instance.new("Part")
	anchor.Name = "BillboardAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = position
	anchor.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FloatingSign"
	billboard.Size = UDim2.fromOffset(width or 420, 92)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 320
	billboard.LightInfluence = 0
	billboard.Adornee = anchor
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.Text = text
	label.Parent = billboard

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(8, 8, 14)
	stroke.Thickness = 3
	stroke.Parent = label
	return anchor
end

local function makeTree(position, scale)
	scale = scale or 1
	local group = Instance.new("Model")
	group.Name = "Tree"
	group.Parent = workspace
	local trunk = cylinder({
		name = "Trunk",
		size = Vector3.new(1.2 * scale, 9 * scale, 1.2 * scale),
		position = position + Vector3.new(0, 4.5 * scale, 0),
		color = PALETTE.wood,
		material = Enum.Material.Wood,
		parent = group,
	})
	for index, offset in ipairs({
		Vector3.new(0, 10.4, 0),
		Vector3.new(-1.9, 9.2, 1.1),
		Vector3.new(1.9, 9.4, -1.0),
		Vector3.new(0.2, 8.4, -2.0),
	}) do
		part({
			name = "Leaves" .. index,
			size = Vector3.new(5.4, 4.4, 5.4) * scale,
			position = position + offset * scale,
			color = index % 2 == 0 and PALETTE.leaf or PALETTE.leafLight,
			material = Enum.Material.Grass,
			shape = Enum.PartType.Ball,
			parent = group,
		})
	end
	return group
end

local function makeLamp(position, rotation)
	local group = Instance.new("Model")
	group.Name = "Lamp"
	group.Parent = workspace
	local pole = cylinder({
		name = "Pole",
		size = Vector3.new(0.8, 14, 0.8),
		position = position + Vector3.new(0, 7, 0),
		color = PALETTE.metalDark,
		material = Enum.Material.Metal,
		parent = group,
	})
	part({
		name = "Arm",
		size = Vector3.new(4.2, 0.5, 0.5),
		position = position + Vector3.new(0, 14, 0),
		cframe = CFrame.new(position + Vector3.new(0, 14, 0)) * CFrame.Angles(0, math.rad(rotation or 0), 0),
		color = PALETTE.metalDark,
		material = Enum.Material.Metal,
		parent = group,
	})
	local bulb = part({
		name = "Bulb",
		size = Vector3.new(1.8, 1.0, 1.8),
		position = position + Vector3.new(2, 13.6, 0),
		color = Color3.fromRGB(255, 236, 172),
		material = Enum.Material.Neon,
		parent = group,
	})
	local light = Instance.new("PointLight")
	light.Brightness = 2.4
	light.Range = 26
	light.Color = Color3.fromRGB(255, 228, 168)
	light.Parent = bulb
	return group
end

local function makePlot(plotIndex)
	local center = Config.PlotCenter(plotIndex)
	local half = Config.PlotSize * 0.5
	local group = Instance.new("Model")
	group.Name = "Plot" .. plotIndex
	group.Parent = workspace

	part({
		name = "Floor",
		size = Vector3.new(Config.PlotSize, Config.PlotTopY, Config.PlotSize),
		position = center + Vector3.new(0, Config.PlotTopY * 0.5, 0),
		color = PALETTE.path,
		material = Enum.Material.Concrete,
		parent = group,
	})
	part({
		name = "Trim",
		size = Vector3.new(Config.PlotSize + 1.6, 0.5, Config.PlotSize + 1.6),
		position = center + Vector3.new(0, 0.2, 0),
		color = PALETTE.pathDark,
		material = Enum.Material.Concrete,
		parent = group,
	})

	for slotIndex = 1, Config.SlotsPerPlot do
		local slotPos = Config.SlotPosition(plotIndex, slotIndex)
		-- The pad's centre sits half its thickness above the deck, so its top
		-- face is exactly where SlotPosition puts a character's feet.
		local pad = part({
			name = "SlotPad" .. slotIndex,
			size = Vector3.new(Config.SlotPadSize, Config.SlotPadHeight, Config.SlotPadSize),
			position = slotPos + Vector3.new(0, -Config.SlotPadHeight * 0.5, 0),
			color = PALETTE.metalDark,
			material = Enum.Material.Metal,
			parent = group,
		})
		pad:SetAttribute("SlotIndex", slotIndex)
		pad:SetAttribute("PlotIndex", plotIndex)
		local inner = part({
			name = "SlotGlow" .. slotIndex,
			size = Vector3.new(Config.SlotPadSize - 1.4, 0.16, Config.SlotPadSize - 1.4),
			position = slotPos + Vector3.new(0, 0.03, 0),
			color = Color3.fromRGB(60, 68, 88),
			material = Enum.Material.Neon,
			transparency = 0.35,
			parent = group,
		})
		inner:SetAttribute("SlotIndex", slotIndex)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TakeNotice"
		prompt.ActionText = "Inspect"
		prompt.ObjectText = "Empty slot"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = pad
	end

	-- Fence posts and rails around the plot, with a gap on the inner side so
	-- players can walk in from the central path.
	local postHeight = 5.4
	for _, edge in ipairs({
		{ axis = "z", sign = -1 },
		{ axis = "z", sign = 1 },
	}) do
		for step = -2, 2 do
			local x = center.X + step * (Config.PlotSize / 5)
			local z = center.Z + edge.sign * (half + 0.7)
			cylinder({
				name = "FencePost",
				size = Vector3.new(0.5, postHeight, 0.5),
				position = Vector3.new(x, postHeight * 0.5, z),
				color = PALETTE.woodDark,
				material = Enum.Material.Wood,
				parent = group,
			})
		end
		part({
			name = "FenceRail",
			size = Vector3.new(Config.PlotSize + 1.4, 0.4, 0.4),
			position = Vector3.new(center.X, postHeight - 0.8, center.Z + edge.sign * (half + 0.7)),
			color = PALETTE.wood,
			material = Enum.Material.Wood,
			parent = group,
		})
		part({
			name = "FenceRailLow",
			size = Vector3.new(Config.PlotSize + 1.4, 0.3, 0.3),
			position = Vector3.new(center.X, 2.2, center.Z + edge.sign * (half + 0.7)),
			color = PALETTE.wood,
			material = Enum.Material.Wood,
			parent = group,
		})
	end

	local outerX = center.X + (center.X < 0 and -(half + 0.7) or (half + 0.7))
	for step = -2, 2 do
		cylinder({
			name = "FencePost",
			size = Vector3.new(0.5, postHeight, 0.5),
			position = Vector3.new(outerX, postHeight * 0.5, center.Z + step * (Config.PlotSize / 5)),
			color = PALETTE.woodDark,
			material = Enum.Material.Wood,
			parent = group,
		})
	end
	part({
		name = "FenceRail",
		size = Vector3.new(0.4, 0.4, Config.PlotSize + 1.4),
		position = Vector3.new(outerX, postHeight - 0.8, center.Z),
		color = PALETTE.wood,
		material = Enum.Material.Wood,
		parent = group,
	})

	-- A name board that shows who owns the plot.
	local boardFrame = part({
		name = "SignFrame",
		size = Vector3.new(0.6, 5.2, 16),
		position = center + Vector3.new(0, 7.4, -(half + 0.8)),
		color = PALETTE.metalDark,
		material = Enum.Material.Metal,
		parent = group,
	})
	local board = part({
		name = "SignBoard",
		size = Vector3.new(0.4, 4.4, 14),
		cframe = CFrame.lookAt(center + Vector3.new(0, 7.4, -(half + 0.5)), center),
		color = Color3.fromRGB(24, 26, 38),
		material = Enum.Material.SmoothPlastic,
		parent = group,
	})
	board:SetAttribute("PlotIndex", plotIndex)
	local surface = Instance.new("SurfaceGui")
	surface.Name = "OwnerSign"
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 34
	surface.LightInfluence = 0
	surface.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "OwnerText"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(170, 240, 255)
	label.Text = "PLOT " .. plotIndex .. "\nUNCLAIMED"
	label.Parent = surface
	group:SetAttribute("OwnerBoard", "SignBoard")
	return group
end

local function makeConveyor()
	local group = Instance.new("Model")
	group.Name = "Conveyor"
	group.Parent = workspace

	local length = Config.ConveyorEndZ - Config.ConveyorStartZ
	local midZ = (Config.ConveyorStartZ + Config.ConveyorEndZ) * 0.5

	part({
		name = "RunwayDeck",
		size = Vector3.new(Config.ConveyorHalfWidth * 2, 1.2, length + 10),
		position = Vector3.new(0, Config.ConveyorTopY - 0.6, midZ),
		color = PALETTE.metal,
		material = Enum.Material.DiamondPlate,
		parent = group,
	})
	part({
		name = "RunwayBed",
		size = Vector3.new(Config.ConveyorHalfWidth * 2 + 1.2, 0.8, length + 11),
		position = Vector3.new(0, Config.ConveyorTopY - 1.5, midZ),
		color = PALETTE.metalDark,
		material = Enum.Material.Metal,
		parent = group,
	})

	-- The moving belt: thin neon strips that scroll so the runway reads as a
	-- belt even while standing still.
	local belt = Instance.new("Model")
	belt.Name = "Belt"
	belt.Parent = group
	for index = 0, math.floor(length / 6) do
		local z = Config.ConveyorStartZ + index * 6
		part({
			name = "BeltSlat" .. index,
			size = Vector3.new(Config.ConveyorHalfWidth * 2 - 1.6, 0.22, 2.2),
			position = Vector3.new(0, Config.ConveyorTopY + 0.06, z),
			color = Color3.fromRGB(74, 210, 226),
			material = Enum.Material.Neon,
			transparency = 0.28,
			parent = belt,
		})
	end
	group:SetAttribute("BeltName", "Belt")

	for _, side in ipairs({ -1, 1 }) do
		part({
			name = "Rail",
			size = Vector3.new(0.4, 3.0, length + 10),
			position = Vector3.new(side * (Config.ConveyorHalfWidth + 0.5), Config.ConveyorTopY + 1.4, midZ),
			color = PALETTE.metalDark,
			material = Enum.Material.Metal,
			parent = group,
		})
		part({
			name = "RailGlow",
			size = Vector3.new(0.24, 0.24, length + 10),
			position = Vector3.new(side * (Config.ConveyorHalfWidth + 0.5), Config.ConveyorTopY + 2.8, midZ),
			color = PALETTE.neon,
			material = Enum.Material.Neon,
			parent = group,
		})
	end

	-- Support legs under the runway.
	for index = 0, 8 do
		local z = Config.ConveyorStartZ + (length / 8) * index
		for _, side in ipairs({ -1, 1 }) do
			cylinder({
				name = "Leg",
				size = Vector3.new(0.8, Config.ConveyorTopY, 0.8),
				position = Vector3.new(side * (Config.ConveyorHalfWidth - 0.6), Config.ConveyorTopY * 0.5 - 0.6, z),
				color = PALETTE.metalDark,
				material = Enum.Material.Metal,
				parent = group,
			})
		end
	end

	--- Arch gates over the runway, one every 22 studs, with a lit top bar.
	for index = 0, 5 do
		local z = Config.ConveyorStartZ + 10 + index * (length / 6)
		for _, side in ipairs({ -1, 1 }) do
			cylinder({
				name = "GatePost",
				size = Vector3.new(0.7, 10, 0.7),
				position = Vector3.new(side * (Config.ConveyorHalfWidth + 2.2), 5.4, z),
				color = PALETTE.metalDark,
				material = Enum.Material.Metal,
				parent = group,
			})
		end
		part({
			name = "GateArch",
			size = Vector3.new(Config.ConveyorHalfWidth * 2 + 5.2, 0.7, 0.7),
			position = Vector3.new(0, 10.1, z),
			color = PALETTE.metalDark,
			material = Enum.Material.Metal,
			parent = group,
		})
		part({
			name = "GateGlow",
			size = Vector3.new(Config.ConveyorHalfWidth * 2 + 5.2, 0.22, 0.22),
			position = Vector3.new(0, 9.7, z),
			color = index % 2 == 0 and PALETTE.neon or PALETTE.pink,
			material = Enum.Material.Neon,
			parent = group,
		})
	end

	-- Stairs at both ends so the runway is walkable, not just visible.
	for _, endZ in ipairs({ Config.ConveyorStartZ - 8, Config.ConveyorEndZ + 8 }) do
		for step = 1, 5 do
			local top = (Config.ConveyorTopY / 5) * step
			part({
				name = "Stair" .. step,
				size = Vector3.new(Config.ConveyorHalfWidth * 2 - 2, top, 2.4),
				position = Vector3.new(0, top * 0.5, endZ + (endZ < 0 and step * 2.4 or -step * 2.4)),
				color = PALETTE.metal,
				material = Enum.Material.DiamondPlate,
				parent = group,
			})
		end
	end

	billboardSign(Vector3.new(0, 16, Config.ConveyorStartZ - 6), "BRAINROT CONVEYOR", Color3.fromRGB(130, 246, 255), 620)
	billboardSign(Vector3.new(0, 13.5, Config.ConveyorEndZ + 12), "GRAB ONE -> BUY IT", Color3.fromRGB(255, 246, 190), 460)
	return group
end

local function makeShop()
	local center = Config.ShopPosition
	local group = Instance.new("Model")
	group.Name = "Shop"
	group.Parent = workspace

	part({
		name = "ShopFloor",
		size = Vector3.new(44, 1, 30),
		position = center + Vector3.new(0, 0.5, 0),
		color = PALETTE.path,
		material = Enum.Material.Concrete,
		parent = group,
	})
	part({
		name = "BackWall",
		size = Vector3.new(44, 15, 1.4),
		position = center + Vector3.new(0, 7.5, 13),
		color = Color3.fromRGB(236, 226, 206),
		material = Enum.Material.Brick,
		parent = group,
	})
	for _, side in ipairs({ -1, 1 }) do
		part({
			name = "SideWall",
			size = Vector3.new(1.4, 15, 26),
			position = center + Vector3.new(side * 21.5, 7.5, 0),
			color = Color3.fromRGB(228, 216, 194),
			material = Enum.Material.Brick,
			parent = group,
		})
	end
	part({
		name = "Counter",
		size = Vector3.new(30, 3.4, 3.4),
		position = center + Vector3.new(0, 1.7, 4.4),
		color = PALETTE.wood,
		material = Enum.Material.Wood,
		parent = group,
	})
	part({
		name = "CounterTop",
		size = Vector3.new(31, 0.4, 4.2),
		position = center + Vector3.new(0, 3.6, 4.4),
		color = Color3.fromRGB(252, 246, 232),
		material = Enum.Material.Marble,
		parent = group,
	})

	-- Awning: alternating stripes sloping out over the front.
	for index = -5, 5 do
		local stripe = part({
			name = "Awning" .. index,
			size = Vector3.new(4.2, 0.3, 8),
			position = center + Vector3.new(index * 4.3, 13.4, 4),
			color = index % 2 == 0 and Color3.fromRGB(238, 92, 112) or Color3.fromRGB(250, 246, 238),
			material = Enum.Material.Fabric,
			parent = group,
		})
		stripe.CFrame = CFrame.new(stripe.Position) * CFrame.Angles(math.rad(-9), 0, 0)
	end

	for _, side in ipairs({ -1, 1 }) do
		local sign = part({
			name = "ShopSign",
			size = Vector3.new(1, 6, 20),
			position = center + Vector3.new(side * 22.4, 10.5, -2),
			color = Color3.fromRGB(30, 26, 44),
			material = Enum.Material.SmoothPlastic,
			parent = group,
		})
		sign.CFrame = CFrame.lookAt(sign.Position, sign.Position + Vector3.new(0, 0, -1))
		local surface = Instance.new("SurfaceGui")
		surface.Face = Enum.NormalId.Front
		surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surface.PixelsPerStud = 38
		surface.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 220, 120)
		label.Text = "BRAINROT SHOP"
		label.Parent = surface
	end

	local buyPad = part({
		name = "BuyPad",
		size = Vector3.new(12, 0.4, 8),
		position = center + Vector3.new(0, 0.2, -6),
		color = Color3.fromRGB(70, 220, 190),
		material = Enum.Material.Neon,
		transparency = 0.35,
		parent = group,
	})
	buyPad:SetAttribute("ShopPad", true)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenShop"
	prompt.ActionText = "Open shop"
	prompt.ObjectText = "Brainrot Shop"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = buyPad

	billboardSign(center + Vector3.new(0, 19, -2), "SHOP", Color3.fromRGB(255, 214, 110), 300)
	return group
end

local function makeAltar()
	local center = Config.AltarPosition
	local group = Instance.new("Model")
	group.Name = "RebirthAltar"
	group.Parent = workspace

	part({
		name = "AltarBase",
		size = Vector3.new(26, 1.2, 26),
		position = center + Vector3.new(0, 0.6, 0),
		color = PALETTE.stone,
		material = Enum.Material.Slate,
		parent = group,
	})
	for step = 1, 3 do
		part({
			name = "AltarStep" .. step,
			size = Vector3.new(26 - step * 5, 0.8, 26 - step * 5),
			position = center + Vector3.new(0, 0.6 + step * 0.8, 0),
			color = PALETTE.stone:Lerp(Color3.fromRGB(90, 84, 120), step * 0.2),
			material = Enum.Material.Slate,
			parent = group,
		})
	end
	local crystal = part({
		name = "Crystal",
		size = Vector3.new(6, 12, 6),
		position = center + Vector3.new(0, 12, 0),
		color = Color3.fromRGB(196, 140, 255),
		material = Enum.Material.Neon,
		transparency = 0.15,
		parent = group,
	})
	crystal.CFrame = CFrame.new(crystal.Position) * CFrame.Angles(math.rad(45), math.rad(45), 0)
	local light = Instance.new("PointLight")
	light.Brightness = 3
	light.Range = 40
	light.Color = Color3.fromRGB(200, 150, 255)
	light.Parent = crystal

	local pad = part({
		name = "RebirthPad",
		size = Vector3.new(9, 0.4, 9),
		position = center + Vector3.new(0, 3.2, 9),
		color = Color3.fromRGB(200, 150, 255),
		material = Enum.Material.Neon,
		transparency = 0.4,
		parent = group,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RebirthPrompt"
	prompt.ActionText = "Rebirth"
	prompt.ObjectText = "Rebirth Altar"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad

	billboardSign(center + Vector3.new(0, 24, 0), "REBIRTH ALTAR", Color3.fromRGB(214, 176, 255), 460)
	return group
end

local function makeSpawnPlaza()
	local group = Instance.new("Model")
	group.Name = "SpawnPlaza"
	group.Parent = workspace
	local center = Config.SpawnPosition
	part({
		name = "Plaza",
		size = Vector3.new(Config.SpawnPlazaSize.X, 1, Config.SpawnPlazaSize.Y),
		position = center + Vector3.new(0, 0.5, 0),
		color = PALETTE.pathDark,
		material = Enum.Material.Cobblestone,
		parent = group,
	})
	for index = 1, 8 do
		local angle = (index / 8) * math.pi * 2
		cylinder({
			name = "PlazaPost" .. index,
			size = Vector3.new(9, 1.4, 1.4),
			position = center + Vector3.new(math.cos(angle) * 26, 4.5, math.sin(angle) * 10),
			color = PALETTE.stone,
			material = Enum.Material.Concrete,
			parent = group,
		})
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = center + Vector3.new(0, 1.2, 0)
	spawn.Color = Color3.fromRGB(120, 220, 250)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.25
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = group
	billboardSign(center + Vector3.new(0, 15, -6), "BRAINROT RUSH", Color3.fromRGB(255, 255, 255), 720)
	return group
end

local function makeDecorations()
	local group = Instance.new("Model")
	group.Name = "Decorations"
	group.Parent = workspace

	local treeSpots = {
		Vector3.new(-104, 0, -78),
		Vector3.new(-104, 0, -14),
		Vector3.new(-104, 0, 52),
		Vector3.new(104, 0, -78),
		Vector3.new(104, 0, -14),
		Vector3.new(104, 0, 52),
		Vector3.new(-38, 0, 96),
		Vector3.new(38, 0, 96),
		Vector3.new(-38, 0, -110),
		Vector3.new(38, 0, -110),
		Vector3.new(-92, 0, 118),
		Vector3.new(92, 0, 118),
	}
	for index, spot in ipairs(treeSpots) do
		local tree = makeTree(spot, 0.9 + (index % 3) * 0.18)
		tree.Parent = group
	end

	local lampSpots = {
		{ Vector3.new(-20, 0, -64), 0 },
		{ Vector3.new(20, 0, -64), 180 },
		{ Vector3.new(-20, 0, 8), 0 },
		{ Vector3.new(20, 0, 8), 180 },
		{ Vector3.new(-20, 0, 64), 0 },
		{ Vector3.new(20, 0, 64), 180 },
		{ Vector3.new(-34, 0, 36), 0 },
		{ Vector3.new(34, 0, 36), 180 },
	}
	for _, entry in ipairs(lampSpots) do
		local lamp = makeLamp(entry[1], entry[2])
		lamp.Parent = group
	end

	-- Cones and crates around the runway for a lived-in market feel.
	for index, spot in ipairs({
		Vector3.new(-11, 0, -40),
		Vector3.new(11, 0, -18),
		Vector3.new(-11, 0, 22),
		Vector3.new(11, 0, 44),
	}) do
		part({
			name = "Crate" .. index,
			size = Vector3.new(4, 4, 4),
			position = spot + Vector3.new(0, 2, 0),
			color = PALETTE.wood,
			material = Enum.Material.WoodPlanks,
			parent = group,
		})
	end
	for index, spot in ipairs({
		Vector3.new(-15, 0, -8),
		Vector3.new(15, 0, 18),
		Vector3.new(-15, 0, 52),
	}) do
		cylinder({
			name = "Cone" .. index,
			size = Vector3.new(3.2, 2.2, 2.2),
			position = spot + Vector3.new(0, 1.6, 0),
			color = Color3.fromRGB(255, 138, 60),
			material = Enum.Material.SmoothPlastic,
			parent = group,
		})
		part({
			name = "ConeStripe",
			size = Vector3.new(2.05, 0.5, 2.05),
			position = spot + Vector3.new(0, 1.4, 0),
			color = Color3.fromRGB(248, 248, 248),
			material = Enum.Material.SmoothPlastic,
			parent = group,
		})
	end

	-- Hanging banners on the shop side of the map.
	for index = -1, 1 do
		local banner = part({
			name = "Banner" .. index,
			size = Vector3.new(5, 12, 0.4),
			position = Vector3.new(index * 34, 9, 74),
			color = Color3.fromRGB(index % 2 == 0 and 240 or 90, index % 2 == 0 and 96 or 200, 160),
			material = Enum.Material.Fabric,
			parent = group,
		})
		local surface = Instance.new("SurfaceGui")
		surface.Face = Enum.NormalId.Front
		surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surface.PixelsPerStud = 30
		surface.Parent = banner
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Text = index == 0 and "STEAL\n& RUN" or (index < 0 and "COLLECT" or "REBIRTH")
		label.Parent = surface
	end
	return group
end

local function makeTerrain()
	local group = Instance.new("Model")
	group.Name = "Ground"
	group.Parent = workspace

	part({
		name = "Baseplate",
		size = Vector3.new(360, 4, 400),
		position = Vector3.new(0, -2, 10),
		color = PALETTE.grass,
		material = Enum.Material.Grass,
		parent = group,
	})
	part({
		name = "BaseSlab",
		size = Vector3.new(364, 2, 404),
		position = Vector3.new(0, -5, 10),
		color = PALETTE.grassDark,
		material = Enum.Material.Ground,
		parent = group,
	})

	-- Paths: a central spine from spawn to the altar, with branches to the
	-- shop and out to each column of plots.
	part({
		name = "MainPath",
		size = Vector3.new(22, 0.4, 210),
		position = Vector3.new(0, 0.2, 4),
		color = PALETTE.path,
		material = Enum.Material.Cobblestone,
		parent = group,
	})
	for _, side in ipairs({ -1, 1 }) do
		for _, branchZ in ipairs({ -42, 0, 42 }) do
			part({
				name = "Branch",
				size = Vector3.new(48, 0.4, 11),
				position = Vector3.new(side * 33, 0.22, branchZ),
				color = PALETTE.path,
				material = Enum.Material.Cobblestone,
				parent = group,
			})
		end
	end
	return group
end

local function configureLighting()
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(96, 92, 118)
	lighting.OutdoorAmbient = Color3.fromRGB(126, 122, 146)
	lighting.Brightness = 2.6
	lighting.ClockTime = 15.2
	lighting.GeographicLatitude = 12
	lighting.EnvironmentDiffuseScale = 0.45
	lighting.EnvironmentSpecularScale = 0.5
	lighting.GlobalShadows = true
	lighting.FogEnd = 900
	lighting.FogStart = 420
	lighting.FogColor = Color3.fromRGB(186, 206, 226)

	if not lighting:FindFirstChild("BrainrotBloom") then
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "BrainrotBloom"
		bloom.Intensity = 0.7
		bloom.Size = 26
		bloom.Threshold = 1.1
		bloom.Parent = lighting
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "BrainrotAir"
		atmosphere.Density = 0.28
		atmosphere.Haze = 1.4
		atmosphere.Glare = 0.2
		atmosphere.Color = Color3.fromRGB(214, 226, 240)
		atmosphere.Decay = Color3.fromRGB(150, 160, 200)
		atmosphere.Parent = lighting
	end
end

-- Clears any previous world build, then builds every part of the map. Returns
-- a table of handles the rest of the server uses.
function WorldBuilder.Build()
	for _, name in ipairs({ "Ground", "Conveyor", "Shop", "RebirthAltar", "SpawnPlaza", "Decorations" }) do
		local existing = workspace:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
	for plotIndex = 1, Config.PlotCount do
		local existing = workspace:FindFirstChild("Plot" .. plotIndex)
		if existing then
			existing:Destroy()
		end
	end

	configureLighting()
	makeTerrain()
	for plotIndex = 1, Config.PlotCount do
		makePlot(plotIndex)
	end
	local conveyor = makeConveyor()
	local shop = makeShop()
	local altar = makeAltar()
	makeSpawnPlaza()
	makeDecorations()

	return {
		conveyor = conveyor,
		shop = shop,
		altar = altar,
	}
end

-- Repaints a plot's name board as ownership changes.
function WorldBuilder.SetPlotLabel(plotIndex, text, color)
	local plot = workspace:FindFirstChild("Plot" .. plotIndex)
	local board = plot and plot:FindFirstChild("SignBoard")
	local surface = board and board:FindFirstChild("OwnerSign")
	local label = surface and surface:FindFirstChild("OwnerText")
	if label then
		label.Text = text
		if color then
			label.TextColor3 = color
		end
	end
end

-- Recolours a slot glow: empty pads stay dark, filled pads take the owner's
-- rarity colour, a locked base flashes red.
function WorldBuilder.SetSlotGlow(plotIndex, slotIndex, color, transparency)
	local plot = workspace:FindFirstChild("Plot" .. plotIndex)
	local glow = plot and plot:FindFirstChild("SlotGlow" .. slotIndex)
	if glow then
		glow.Color = color
		glow.Transparency = transparency or 0.3
	end
end

-- Where a walking brainrot's feet go: on top of the belt.
function WorldBuilder.ConveyorPoint(progress)
	local z = Config.ConveyorStartZ + (Config.ConveyorEndZ - Config.ConveyorStartZ) * progress
	return Vector3.new(0, Config.ConveyorTopY + 0.2, z)
end

return WorldBuilder
