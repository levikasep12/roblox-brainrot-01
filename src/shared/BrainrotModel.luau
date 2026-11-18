-- Builds a brainrot's 3D body from parts only: no uploaded assets, so the
-- models always load for a reviewer. One function per body shape plus small
-- prop build the silhouette; the name/rarity/income label is a BillboardGui.

local BrainrotDefs = require(script.Parent.BrainrotDefs)

local BrainrotModel = {}

local function newPart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function buildBody(def, model)
	local root = newPart("Body", Vector3.new(3.4, 3.4, 3.4), def.bodyColor)
	root.Shape = Enum.PartType.Ball
	root.Position = Vector3.new(0, 1.9, 0)
	root.Parent = model

	local torso = newPart("Torso", Vector3.new(2.6, 2.2, 2.2), def.bodyColor)
	torso.Position = Vector3.new(0, 3.5, 0)
	torso.Parent = model

	if def.shape == "box" then
		root.Shape = Enum.PartType.Block
		root.Size = Vector3.new(3.2, 3, 3.2)
		root.Position = Vector3.new(0, 1.7, 0)
		torso.Size = Vector3.new(3.4, 2.4, 3.4)
		torso.Position = Vector3.new(0, 4.2, 0)
	elseif def.shape == "cone" then
		root.Shape = Enum.PartType.Cylinder
		root.Size = Vector3.new(3.4, 2.4, 2.4)
		root.CFrame = CFrame.new(0, 1.9, 0) * CFrame.Angles(0, 0, math.rad(90))
		root.Color = def.bodyColor
		torso:Destroy()
	end

	-- Two eyes and a tiny mouth: cheap parts that read as a face from any angle.
	for _, side in ipairs({ -1, 1 }) do
		local eye = newPart("Eye", Vector3.new(0.55, 0.7, 0.3), Color3.fromRGB(250, 250, 250))
		eye.Position = Vector3.new(side * 0.75, 4.3, 1.62)
		eye.Parent = model
		local pupil = newPart("Pupil", Vector3.new(0.28, 0.34, 0.16), Color3.fromRGB(24, 24, 32))
		pupil.Position = Vector3.new(side * 0.75, 4.28, 1.78)
		pupil.Parent = model
	end
	local mouth = newPart("Mouth", Vector3.new(0.9, 0.16, 0.2), Color3.fromRGB(40, 28, 34))
	mouth.Position = Vector3.new(0, 3.5, 1.66)
	mouth.Parent = model
end

local function buildChefHat(model, def)
	local band = newPart("HatBand", Vector3.new(2.2, 0.5, 2.2), def.accentColor)
	band.Position = Vector3.new(0, 5.85, 0)
	band.Parent = model
	local puff = newPart("HatPuff", Vector3.new(2.8, 1.6, 2.8), def.accentColor)
	puff.Shape = Enum.PartType.Ball
	puff.Position = Vector3.new(0, 6.9, 0)
	puff.Parent = model
end

local function buildAntenna(model, def)
	local pole = newPart("Antenna", Vector3.new(0.2, 1.6, 0.2), def.accentColor)
	pole.Position = Vector3.new(0, 7.3, 0)
	pole.Parent = model
	local bulb = newPart("AntennaBulb", Vector3.new(0.8, 0.8, 0.8), def.accentColor)
	bulb.Shape = Enum.PartType.Ball
	bulb.Position = Vector3.new(0, 8.2, 0)
	bulb.Parent = model
end

local function buildHeadphones(model, def)
	local band = newPart("Headband", Vector3.new(2.6, 0.4, 0.5), def.accentColor)
	band.Position = Vector3.new(0, 6.35, 0)
	band.Parent = model
	for _, side in ipairs({ -1, 1 }) do
		local can = newPart("HeadphoneCan", Vector3.new(0.5, 1.4, 1.4), def.accentColor)
		can.Position = Vector3.new(side * 1.55, 5.6, 0)
		can.Parent = model
	end
end

local function buildTopHat(model, def)
	local brim = newPart("HatBrim", Vector3.new(2.6, 0.2, 2.6), def.accentColor)
	brim.Position = Vector3.new(0, 5.6, 0)
	brim.Parent = model
	local crown = newPart("HatCrown", Vector3.new(1.7, 1.8, 1.7), def.accentColor)
	crown.Position = Vector3.new(0, 6.6, 0)
	crown.Parent = model
end

local function buildCup(model, def)
	local cup = newPart("CoffeeCup", Vector3.new(1.1, 1.4, 1.1), def.accentColor)
	cup.Shape = Enum.PartType.Cylinder
	cup.CFrame = CFrame.new(2.4, 3.4, 0.8) * CFrame.Angles(0, 0, math.rad(90))
	cup.Parent = model
end

local function buildWings(model, def)
	for _, side in ipairs({ -1, 1 }) do
		local wing = newPart("Wing", Vector3.new(0.25, 2.6, 2.2), def.accentColor)
		wing.Position = Vector3.new(side * 2.1, 4.4, -0.2)
		wing.Parent = model
	end
end

local function buildHeadband(model, def)
	local band = newPart("Headband", Vector3.new(2.9, 0.45, 2.9), def.accentColor)
	band.Position = Vector3.new(0, 5.05, 0)
	band.Parent = model
end

local function buildBriefcase(model, def)
	local case = newPart("Briefcase", Vector3.new(1.6, 1.1, 0.6), def.accentColor)
	case.Position = Vector3.new(2.4, 2.2, 1.0)
	case.Parent = model
end

local function buildHalo(model, def)
	local halo = newPart("Halo", Vector3.new(2.6, 0.25, 2.6), def.accentColor)
	halo.Shape = Enum.PartType.Cylinder
	halo.CFrame = CFrame.new(0, 8.1, 0) * CFrame.Angles(0, 0, math.rad(90))
	halo.Material = Enum.Material.Neon
	halo.Parent = model
end

local function buildCrown(model, def)
	local crown = newPart("Crown", Vector3.new(2.4, 0.9, 2.4), def.accentColor)
	crown.Material = Enum.Material.Neon
	crown.Position = Vector3.new(0, 6.6, 0)
	crown.Parent = model
	for _, offset in ipairs({ Vector3.new(-1, 7.3, -1), Vector3.new(1, 7.3, -1), Vector3.new(0, 7.3, 1) }) do
		local spike = newPart("CrownSpike", Vector3.new(0.5, 0.8, 0.5), def.accentColor)
		spike.Material = Enum.Material.Neon
		spike.Position = offset
		spike.Parent = model
	end
end

local function buildDisco(model, def)
	local ball = newPart("DiscoBall", Vector3.new(1.9, 1.9, 1.9), def.accentColor)
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.Neon
	ball.Position = Vector3.new(0, 7.4, 0)
	ball.Parent = model
end

local function buildGlasses(model, def)
	local bar = newPart("Glasses", Vector3.new(2.3, 0.3, 0.25), def.accentColor)
	bar.Position = Vector3.new(0, 4.35, 1.7)
	bar.Parent = model
end

local propBuilders = {
	chefhat = buildChefHat,
	antenna = buildAntenna,
	headphones = buildHeadphones,
	tophat = buildTopHat,
	cup = buildCup,
	wings = buildWings,
	headband = buildHeadband,
	briefcase = buildBriefcase,
	halo = buildHalo,
	crown = buildCrown,
	disco = buildDisco,
	glasses = buildGlasses,
}

-- A small name / rarity / income label, about 150x46, that hides behind nearer ones instead of
-- stacking through them (AlwaysOnTop = false).
function BrainrotModel.buildLabel(def, ratePerSecond, mutation)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "InfoLabel"
	billboard.Size = UDim2.fromOffset(150, 46)
	billboard.StudsOffset = Vector3.new(0, 9.4, 0)
	billboard.AlwaysOnTop = false
	billboard.LightInfluence = 1
	billboard.MaxDistance = 160
	billboard.Adornee = nil

	local frame = Instance.new("Frame")
	frame.Name = "Card"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local streak = Instance.new("Frame")
	streak.Name = "RarityStreak"
	streak.Size = UDim2.new(0, 4, 1, 0)
	streak.BackgroundColor3 = BrainrotDefs.RarityColors[def.rarity] or Color3.new(1, 1, 1)
	streak.BorderSizePixel = 0
	streak.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Position = UDim2.fromOffset(10, 3)
	nameLabel.Size = UDim2.new(1, -14, 0, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextColor3 = Color3.fromRGB(245, 245, 250)
	nameLabel.Text = (mutation and (mutation .. " ") or "") .. def.name
	nameLabel.Parent = frame

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Detail"
	subLabel.Position = UDim2.fromOffset(10, 22)
	subLabel.Size = UDim2.new(1, -14, 0, 18)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Enum.Font.GothamMedium
	subLabel.TextSize = 12
	subLabel.TextXAlignment = Enum.TextXAlignment.Left
	subLabel.TextColor3 = BrainrotDefs.RarityColors[def.rarity] or Color3.new(1, 1, 1)
	subLabel.Text = string.format("%s  $%d/s", def.rarity, ratePerSecond)
	subLabel.Parent = frame

	return billboard
end

-- A full brainrot model: body, prop, label, and a Mutation ring when it is Golden or Diamond.
function BrainrotModel.build(def, ratePerSecond, mutation)
	local model = Instance.new("Model")
	model.Name = def.id

	buildBody(def, model)
	local buildProp = propBuilders[def.prop]
	if buildProp then
		buildProp(model, def)
	end

	if mutation == "Golden" then
		for _, part in ipairs(model:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "Pupil" then
				part.Material = Enum.Material.Neon
				part.Color = Color3.fromRGB(255, 196, 48)
			end
		end
	elseif mutation == "Diamond" then
		for _, part in ipairs(model:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "Pupil" then
				part.Material = Enum.Material.Glass
				part.Color = Color3.fromRGB(150, 226, 255)
				part.Transparency = 0.15
			end
		end
	end

	local label = BrainrotModel.buildLabel(def, ratePerSecond, mutation)
	label.Adornee = model:FindFirstChild("Torso") or model:FindFirstChild("Body")
	label.Parent = model

	model.PrimaryPart = model:FindFirstChild("Body")
	return model
end

return BrainrotModel
