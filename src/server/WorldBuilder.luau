-- Builds the whole 3D world from parts at server start: the baseplate, the central
-- conveyor runway brainrots walk along, the six player plots with their slots, the
-- shop counter, a giant brainrot statue centerpiece, entrance arches, planters, lamps
-- and signs. Returns the folder plus the plot and slot parts other modules need.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local WorldBuilder = {}

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Name = props.name or "Part"
	p.Size = props.size or Vector3.new(4, 4, 4)
	p.CFrame = props.cframe or CFrame.new(props.position or Vector3.new(0, 2, 0))
	p.Color = props.color or Color3.fromRGB(200, 200, 200)
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Transparency = props.transparency or 0
	p.CanCollide = props.collide ~= false
	return p
end

local function labelOnFace(parent, text, color, face, guiName)
	local gui = Instance.new("SurfaceGui")
	gui.Name = guiName or "SignText"
	gui.Face = face
	gui.CanvasSize = Vector2.new(500, 160)
	gui.Parent = parent

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.TextScaled = true
	textLabel.Text = text
	textLabel.TextColor3 = color or Color3.new(1, 1, 1)
	textLabel.Parent = gui
end

-- A free-standing sign reads from both sides, so a player sees it whichever way they walk up.
local function labelPart(parent, text, color)
	labelOnFace(parent, text, color, Enum.NormalId.Front, "SignText")
	labelOnFace(parent, text, color, Enum.NormalId.Back, "SignTextBack")
end

local function buildGround(world)
	local ground = part({
		name = "Ground",
		size = Vector3.new(Config.World.groundSize, 4, Config.World.groundSize),
		position = Vector3.new(0, -2, 0),
		color = Color3.fromRGB(48, 132, 108),
		material = Enum.Material.Grass,
	})
	ground.Parent = world

	-- A lighter plaza tile under the conveyor and shop so the play area reads as one place.
	local plaza = part({
		name = "Plaza",
		size = Vector3.new(210, 0.4, 190),
		position = Vector3.new(0, 0.1, 6),
		color = Color3.fromRGB(206, 206, 214),
		material = Enum.Material.Concrete,
		collide = false,
	})
	plaza.Parent = world

	for _, ring in ipairs({ 60, 120, 180 }) do
		local band = part({
			name = "PathRing",
			size = Vector3.new(8, 0.45, ring * 2 - 20),
			position = Vector3.new(0, 0.12, 6),
			color = Color3.fromRGB(178, 186, 196),
			material = Enum.Material.Concrete,
			collide = false,
		})
		band.Parent = world
		local across = part({
			name = "PathRing",
			size = Vector3.new(ring * 2 - 20, 0.45, 8),
			position = Vector3.new(0, 0.12, 6),
			color = Color3.fromRGB(178, 186, 196),
			material = Enum.Material.Concrete,
			collide = false,
		})
		across.Parent = world
	end
end

local function buildConveyor(world)
	local conveyor = Instance.new("Folder")
	conveyor.Name = "Conveyor"
	conveyor.Parent = world

	local deckY = Config.World.conveyorDeckY
	local width = Config.World.conveyorWidth
	local length = Config.World.conveyorLength
	local startZ = Config.World.conveyorStartZ

	local frame = part({
		name = "ConveyorFrame",
		size = Vector3.new(width + 5, 3.2, length + 8),
		position = Vector3.new(0, deckY - 2, startZ + length / 2),
		color = Color3.fromRGB(52, 56, 66),
		material = Enum.Material.Metal,
	})
	frame.Parent = conveyor

	local deck = part({
		name = "ConveyorDeck",
		size = Vector3.new(width, 0.6, length),
		position = Vector3.new(0, deckY, startZ + length / 2),
		color = Color3.fromRGB(84, 88, 100),
		material = Enum.Material.Metal,
	})
	deck.Parent = conveyor

	-- Moving belt stripes: thin slats that the server slides along the deck.
	for i = 1, 22 do
		local z = startZ - 2 + ((i - 1) * (length / 22))
		local slat = part({
			name = "BeltSlat",
			size = Vector3.new(width - 1, 0.16, 1.4),
			position = Vector3.new(0, deckY + 0.36, z),
			color = Color3.fromRGB(126, 132, 148),
			material = Enum.Material.DiamondPlate,
			collide = false,
		})
		slat.Parent = conveyor
	end

	for _, side in ipairs({ -1, 1 }) do
		local rail = part({
			name = "ConveyorRail",
			size = Vector3.new(0.8, 2.2, length + 8),
			position = Vector3.new(side * (width / 2 + 2), deckY + 1.2, startZ + length / 2),
			color = Color3.fromRGB(255, 172, 56),
			material = Enum.Material.Metal,
		})
		rail.Parent = conveyor
	end

	local banner = part({
		name = "ConveyorSign",
		size = Vector3.new(30, 5, 1),
		position = Vector3.new(0, 13, startZ - 2),
		color = Color3.fromRGB(28, 30, 40),
		material = Enum.Material.SmoothPlastic,
		collide = false,
	})
	banner.CFrame = CFrame.new(0, 13, startZ - 2) * CFrame.Angles(math.rad(-12), 0, 0)
	banner.Parent = conveyor
	labelPart(banner, "BRAINROT RUNWAY", Color3.fromRGB(255, 214, 92))

	for _, side in ipairs({ -1, 1 }) do
		local post = part({
			name = "SignPost",
			size = Vector3.new(0.8, 12, 0.8),
			position = Vector3.new(side * 14, 6, startZ - 2),
			color = Color3.fromRGB(64, 68, 80),
			material = Enum.Material.Metal,
		})
		post.Parent = conveyor
	end

	-- A glowing spawn ring at the runway's far end, where brainrots appear.
	local ring = part({
		name = "SpawnRing",
		size = Vector3.new(width + 6, 0.5, 6),
		position = Vector3.new(0, deckY + 0.4, startZ - 3),
		color = Color3.fromRGB(120, 240, 200),
		material = Enum.Material.Neon,
		collide = false,
	})
	ring.Parent = conveyor

	return conveyor
end

local function buildPlots(world)
	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = world

	local plotParts = {}
	-- Six distinct tints so each base reads as its own place in a wide shot.
	local plotColors = {
		Color3.fromRGB(74, 82, 118),
		Color3.fromRGB(92, 78, 116),
		Color3.fromRGB(70, 96, 112),
		Color3.fromRGB(108, 84, 96),
		Color3.fromRGB(78, 104, 92),
		Color3.fromRGB(100, 92, 120),
	}
	for index, center in ipairs(Config.World.plotCenters) do
		local plot = part({
			name = "Plot" .. index,
			size = Vector3.new(Config.World.plotHalfWidth * 2, 1.2, Config.World.plotHalfDepth * 2),
			position = center + Vector3.new(0, 0.6, 0),
			color = plotColors[index] or Color3.fromRGB(86, 96, 136),
			material = Enum.Material.Slate,
		})
		plot.Parent = plots
		plot:SetAttribute("PlotIndex", index)

		local glow = part({
			name = "PlotEdge",
			size = Vector3.new(Config.World.plotHalfWidth * 2 + 1.6, 0.5, Config.World.plotHalfDepth * 2 + 1.6),
			position = center + Vector3.new(0, 1.05, 0),
			color = Color3.fromRGB(120, 220, 255),
			material = Enum.Material.Neon,
			collide = false,
			transparency = 0.15,
		})
		glow.Parent = plots

		local ownerSign = part({
			name = "OwnerSign",
			size = Vector3.new(14, 4.5, 0.6),
			position = center + Vector3.new(0, 5, -Config.World.plotHalfDepth - 2),
			color = Color3.fromRGB(24, 26, 36),
			material = Enum.Material.SmoothPlastic,
			collide = false,
		})
		ownerSign.CFrame = CFrame.new(center + Vector3.new(0, 5, -Config.World.plotHalfDepth - 2))
			* CFrame.Angles(math.rad(-10), 0, 0)
		ownerSign.Parent = plots
		labelPart(ownerSign, "PLOT " .. index, Color3.fromRGB(140, 230, 255))

		local slotParts = {}
		for slotIndex, offset in ipairs(Config.World.slotOffsets) do
			local pad = part({
				name = "Slot" .. slotIndex,
				size = Config.World.slotPadSize,
				position = center + offset + Vector3.new(0, 1.45, 0),
				color = Color3.fromRGB(52, 58, 84),
				material = Enum.Material.Metal,
				collide = false,
			})
			pad.Parent = plots
			pad:SetAttribute("PlotIndex", index)
			pad:SetAttribute("SlotIndex", slotIndex)

			local trim = part({
				name = "SlotTrim",
				size = Vector3.new(Config.World.slotPadSize.X + 0.6, 0.2, Config.World.slotPadSize.Z + 0.6),
				position = center + offset + Vector3.new(0, 1.78, 0),
				color = Color3.fromRGB(96, 132, 200),
				material = Enum.Material.Neon,
				collide = false,
			})
			trim.Parent = plots

			table.insert(slotParts, pad)
		end

		table.insert(plotParts, { center = center, plot = plot, slots = slotParts, sign = ownerSign })
	end

	return plots, plotParts
end

local function buildShop(world)
	local shop = Instance.new("Folder")
	shop.Name = "Shop"
	shop.Parent = world

	local base = part({
		name = "ShopBase",
		size = Vector3.new(56, 1.2, 24),
		position = Vector3.new(0, 0.6, 78),
		color = Color3.fromRGB(94, 66, 48),
		material = Enum.Material.WoodPlanks,
	})
	base.Parent = shop

	local counter = part({
		name = "ShopCounter",
		size = Vector3.new(40, 4, 3),
		position = Vector3.new(0, 3, 66),
		color = Color3.fromRGB(140, 96, 64),
		material = Enum.Material.WoodPlanks,
	})
	counter.Parent = shop

	for _, side in ipairs({ -1, 1 }) do
		local post = part({
			name = "ShopPost",
			size = Vector3.new(1.4, 12, 1.4),
			position = Vector3.new(side * 18, 7, 84),
			color = Color3.fromRGB(110, 76, 52),
			material = Enum.Material.WoodPlanks,
		})
		post.Parent = shop
	end

	local roof = part({
		name = "ShopRoof",
		size = Vector3.new(48, 1.2, 26),
		position = Vector3.new(0, 15, 78),
		color = Color3.fromRGB(200, 68, 84),
		material = Enum.Material.Fabric,
	})
	roof.CFrame = CFrame.new(0, 15, 78) * CFrame.Angles(math.rad(-6), 0, 0)
	roof.Parent = shop

	local sign = part({
		name = "ShopSign",
		size = Vector3.new(30, 6, 0.8),
		position = Vector3.new(0, 11, 63),
		color = Color3.fromRGB(28, 30, 40),
		material = Enum.Material.SmoothPlastic,
		collide = false,
	})
	sign.Parent = shop
	labelPart(sign, "BRAINROT SHOP", Color3.fromRGB(255, 226, 120))

	return shop
end

local function buildDecor(world)
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = world

	local treeSpots = {
		Vector3.new(-150, 0, -150),
		Vector3.new(-95, 0, 130),
		Vector3.new(120, 0, -140),
		Vector3.new(150, 0, 90),
		Vector3.new(-150, 0, 60),
		Vector3.new(24, 0, -120),
		Vector3.new(-24, 0, 120),
		Vector3.new(145, 0, -20),
	}
	for index, spot in ipairs(treeSpots) do
		local trunk = part({
			name = "TreeTrunk",
			size = Vector3.new(3, 12, 3),
			position = spot + Vector3.new(0, 6, 0),
			color = Color3.fromRGB(96, 66, 44),
			material = Enum.Material.Wood,
		})
		trunk.Parent = decor
		local leaves = part({
			name = "TreeLeaves",
			size = Vector3.new(12, 12, 12),
			position = spot + Vector3.new(0, 15, 0),
			color = index % 3 == 0 and Color3.fromRGB(70, 156, 96) or Color3.fromRGB(58, 138, 86),
			material = Enum.Material.Grass,
		})
		leaves.Parent = decor
	end

	local lampSpots = {
		Vector3.new(-34, 0, -46),
		Vector3.new(34, 0, -46),
		Vector3.new(-34, 0, 38),
		Vector3.new(34, 0, 38),
		Vector3.new(-26, 0, 14),
		Vector3.new(26, 0, 14),
	}
	for _, spot in ipairs(lampSpots) do
		local pole = part({
			name = "LampPost",
			size = Vector3.new(0.8, 16, 0.8),
			position = spot + Vector3.new(0, 8, 0),
			color = Color3.fromRGB(46, 50, 60),
			material = Enum.Material.Metal,
		})
		pole.Parent = decor
		local bulb = part({
			name = "LampBulb",
			size = Vector3.new(2.4, 2.4, 2.4),
			position = spot + Vector3.new(0, 16, 0),
			color = Color3.fromRGB(255, 232, 168),
			material = Enum.Material.Neon,
			collide = false,
		})
		bulb.Shape = Enum.PartType.Ball
		bulb.Parent = decor
		local light = Instance.new("PointLight")
		light.Brightness = 1.2
		light.Range = 26
		light.Color = Color3.fromRGB(255, 236, 186)
		light.Parent = bulb
	end

	local billboard = part({
		name = "WelcomeSign",
		size = Vector3.new(34, 9, 0.8),
		position = Vector3.new(0, 9, 106),
		color = Color3.fromRGB(20, 22, 30),
		material = Enum.Material.SmoothPlastic,
		collide = false,
	})
	billboard.CFrame = CFrame.new(0, 9, 106) * CFrame.Angles(math.rad(-8), 0, 0)
	billboard.Parent = decor
	labelPart(billboard, "BRAINROT RUSH", Color3.fromRGB(255, 124, 184))

	for _, side in ipairs({ -1, 1 }) do
		local post = part({
			name = "WelcomePost",
			size = Vector3.new(0.8, 9, 0.8),
			position = Vector3.new(side * 15, 4.5, 106),
			color = Color3.fromRGB(56, 60, 72),
			material = Enum.Material.Metal,
		})
		post.Parent = decor
	end
end

-- A giant brainrot statue on a pedestal off the plaza's east side: the landmark every wide
-- screenshot frames. Built from the same primitive parts as the cast, clear of the conveyor.
local function buildCenterpiece(world)
	local decor = world:FindFirstChild("Decor") or world
	local baseX, baseZ = 118, 6

	local pedestal = part({
		name = "StatuePedestal",
		size = Vector3.new(26, 6, 26),
		position = Vector3.new(baseX, 3, baseZ),
		color = Color3.fromRGB(60, 64, 82),
		material = Enum.Material.Marble,
	})
	pedestal.Parent = decor

	local plaque = part({
		name = "StatuePlaque",
		size = Vector3.new(20, 3, 1),
		position = Vector3.new(baseX, 3, baseZ - 13.5),
		color = Color3.fromRGB(24, 26, 36),
		material = Enum.Material.SmoothPlastic,
		collide = false,
	})
	plaque.Parent = decor
	labelPart(plaque, "THE FIRST BRAINROT", Color3.fromRGB(255, 214, 92))

	local head = part({
		name = "StatueHead",
		size = Vector3.new(16, 16, 16),
		position = Vector3.new(baseX, 14, baseZ),
		color = Color3.fromRGB(255, 196, 48),
		material = Enum.Material.Neon,
		collide = false,
	})
	head.Shape = Enum.PartType.Ball
	head.Parent = decor

	for _, side in ipairs({ -1, 1 }) do
		local eye = part({
			name = "StatueEye",
			size = Vector3.new(3.4, 4, 1.4),
			position = Vector3.new(baseX + side * 4, 16, baseZ - 7.2),
			color = Color3.fromRGB(250, 250, 250),
			material = Enum.Material.SmoothPlastic,
			collide = false,
		})
		eye.Parent = decor
		local pupil = part({
			name = "StatuePupil",
			size = Vector3.new(1.6, 2, 0.8),
			position = Vector3.new(baseX + side * 4, 16, baseZ - 8.1),
			color = Color3.fromRGB(24, 24, 32),
			material = Enum.Material.SmoothPlastic,
			collide = false,
		})
		pupil.Parent = decor
	end

	local crown = part({
		name = "StatueCrown",
		size = Vector3.new(12, 3, 12),
		position = Vector3.new(baseX, 23, baseZ),
		color = Color3.fromRGB(255, 84, 132),
		material = Enum.Material.Neon,
		collide = false,
	})
	crown.Parent = decor
	for _, offset in ipairs({ Vector3.new(-4, 25, 0), Vector3.new(4, 25, 0), Vector3.new(0, 25, -4), Vector3.new(0, 25, 4) }) do
		local spike = part({
			name = "StatueSpike",
			size = Vector3.new(2, 4, 2),
			position = Vector3.new(baseX + offset.X, offset.Y, baseZ + offset.Z),
			color = Color3.fromRGB(255, 84, 132),
			material = Enum.Material.Neon,
			collide = false,
		})
		spike.Parent = decor
	end
end

-- Two entrance arches framing the runway approach, so the spawn side reads as a gateway.
local function buildEntranceArches(world)
	local decor = world:FindFirstChild("Decor") or world
	for _, z in ipairs({ -62, 62 }) do
		for _, side in ipairs({ -1, 1 }) do
			local pillar = part({
				name = "ArchPillar",
				size = Vector3.new(2.4, 20, 2.4),
				position = Vector3.new(side * 22, 10, z),
				color = Color3.fromRGB(70, 76, 96),
				material = Enum.Material.Metal,
			})
			pillar.Parent = decor
			local lightStrip = part({
				name = "ArchLight",
				size = Vector3.new(0.6, 18, 0.6),
				position = Vector3.new(side * 21, 10, z + 1.3),
				color = Color3.fromRGB(120, 220, 255),
				material = Enum.Material.Neon,
				collide = false,
			})
			lightStrip.Parent = decor
		end
		local beam = part({
			name = "ArchBeam",
			size = Vector3.new(46, 3, 2.4),
			position = Vector3.new(0, 21, z),
			color = Color3.fromRGB(40, 44, 60),
			material = Enum.Material.SmoothPlastic,
		})
		beam.Parent = decor
		labelPart(beam, "BRAINROT RUSH", Color3.fromRGB(255, 214, 92))
	end
end

-- Rounded planters with a shrub flanking each plot's back edge, adding green mass to the
-- wide shots without sitting on any slot pad (they sit just behind the plot, either side
-- of the owner sign).
local function buildPlanters(world)
	local decor = world:FindFirstChild("Decor") or world
	for _, center in ipairs(Config.World.plotCenters) do
		for _, side in ipairs({ -1, 1 }) do
			local spot = center + Vector3.new(side * (Config.World.plotHalfWidth - 2), 0, -Config.World.plotHalfDepth - 1)
			local planter = part({
				name = "Planter",
				size = Vector3.new(4, 2, 4),
				position = spot + Vector3.new(0, 1.6, 0),
				color = Color3.fromRGB(120, 82, 56),
				material = Enum.Material.WoodPlanks,
			})
			planter.Parent = decor
			local shrub = part({
				name = "PlanterShrub",
				size = Vector3.new(4.4, 4, 4.4),
				position = spot + Vector3.new(0, 4, 0),
				color = Color3.fromRGB(72, 160, 96),
				material = Enum.Material.Grass,
				collide = false,
			})
			shrub.Shape = Enum.PartType.Ball
			shrub.Parent = decor
		end
	end
end

-- Builds everything under a Workspace folder named "Arena".
function WorldBuilder.build()
	local existing = workspace:FindFirstChild("Arena")
	if existing then
		existing:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "Arena"

	buildGround(world)
	buildConveyor(world)
	local _, plotParts = buildPlots(world)
	buildShop(world)
	buildDecor(world)
	buildCenterpiece(world)
	buildEntranceArches(world)
	buildPlanters(world)

	-- Visible decorative pad: the ground a spawning character stands on, so the spawn reads
	-- in screenshots. It is a plain part, not the SpawnLocation itself.
	local spawnX = Config.World.spawnPosition.X
	local spawnY = Config.World.spawnPosition.Y
	local spawnZ = Config.World.spawnPosition.Z
	local spawnPad = part({
		name = "SpawnPad",
		size = Vector3.new(14, 1, 14),
		position = Vector3.new(spawnX, 0.5, spawnZ),
		color = Color3.fromRGB(96, 200, 255),
		material = Enum.Material.Neon,
	})
	spawnPad.Parent = world

	-- The real spawn point is invisible and non-colliding, parented straight to workspace so
	-- it is never buried in a folder, and guarded so a rebuild cannot duplicate it. Characters
	-- spawn above it and drop onto the pad below: no pivot, no teleport.
	local existingSpawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if not existingSpawn then
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "PlayerSpawn"
		spawn.Size = Vector3.new(14, 1, 14)
		spawn.Position = Vector3.new(spawnX, spawnY - 2, spawnZ)
		spawn.Anchored = true
		spawn.Transparency = 1
		spawn.CanCollide = false
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Parent = workspace
	end

	world.Parent = workspace
	return world, plotParts
end

return WorldBuilder
