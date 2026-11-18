-- Builds a brainrot's 3D body from parts only: no uploaded assets, so the
-- models always load for a reviewer. One function per body shape plus small
-- prop build the silhouette; the name/rarity/income label is a BillboardGui.

local BrainrotDefs = require(script.Parent.BrainrotDefs)
local Config = require(script.Parent.Config)

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

-- The body per shape, plus the point the face is mounted on: every shape returns the
-- head centre and its front depth so the eyes and mouth sit on the surface, never float.
local function buildBody(def, model)
	local headY = 3.6
	local faceZ = 1.15

	if def.shape == "box" then
		local body = newPart("Body", Vector3.new(3.4, 3.4, 3.4), def.bodyColor)
		body.Position = Vector3.new(0, 1.8, 0)
		body.Parent = model

		local torso = newPart("Torso", Vector3.new(3.6, 2.4, 3.6), def.bodyColor)
		torso.Position = Vector3.new(0, 3.6, 0)
		torso.Parent = model
		headY, faceZ = 3.9, 1.85
	elseif def.shape == "cone" then
		local base = newPart("Body", Vector3.new(3.6, 1.2, 3.6), def.bodyColor)
		base.Shape = Enum.PartType.Cylinder
		base.CFrame = CFrame.new(0, 1.1, 0) * CFrame.Angles(0, 0, math.rad(90))
		base.Parent = model

		local torso = newPart("Torso", Vector3.new(3.2, 2.6, 3.2), def.bodyColor)
		torso.Shape = Enum.PartType.Cylinder
		torso.CFrame = CFrame.new(0, 3.2, 0) * CFrame.Angles(0, 0, math.rad(90))
		torso.Parent = model

		local tip = newPart("Tip", Vector3.new(1.6, 1.4, 1.6), def.accentColor)
		tip.Shape = Enum.PartType.Cylinder
		tip.CFrame = CFrame.new(0, 5.1, 0) * CFrame.Angles(0, 0, math.rad(90))
		tip.Parent = model
		headY, faceZ = 3.4, 1.55
	else
		local body = newPart("Body", Vector3.new(3.4, 3.4, 3.4), def.bodyColor)
		body.Shape = Enum.PartType.Ball
		body.Position = Vector3.new(0, 1.9, 0)
		body.Parent = model

		local torso = newPart("Torso", Vector3.new(2.6, 2.2, 2.6), def.bodyColor)
		torso.Position = Vector3.new(0, 3.7, 0)
		torso.Parent = model
		headY, faceZ = 3.8, 1.32
	end

	for _, side in ipairs({ -1, 1 }) do
		local eye = newPart("Eye", Vector3.new(0.55, 0.7, 0.3), Color3.fromRGB(250, 250, 250))
		eye.Position = Vector3.new(side * 0.7, headY + 0.45, faceZ)
		eye.Parent = model

		local pupil = newPart("Pupil", Vector3.new(0.26, 0.32, 0.16), Color3.fromRGB(24, 24, 32))
		pupil.Position = Vector3.new(side * 0.7, headY + 0.43, faceZ + 0.14)
		pupil.Parent = model
	end

	local mouth = newPart("Mouth", Vector3.new(0.9, 0.16, 0.2), Color3.fromRGB(40, 28, 34))
	mouth.Position = Vector3.new(0, headY - 0.35, faceZ + 0.04)
	mouth.Parent = model

	return headY, faceZ
end

local function buildChefHat(model, def, topY)
	local band = newPart("HatBand", Vector3.new(2.2, 0.5, 2.2), def.accentColor)
	band.Position = Vector3.new(0, topY + 0.25, 0)
	band.Parent = model
	local puff = newPart("HatPuff", Vector3.new(2.8, 1.6, 2.8), def.accentColor)
	puff.Shape = Enum.PartType.Ball
	puff.Position = Vector3.new(0, topY + 1.2, 0)
	puff.Parent = model
end

local function buildAntenna(model, def, topY)
	local pole = newPart("Antenna", Vector3.new(0.2, 1.6, 0.2), def.accentColor)
	pole.Position = Vector3.new(0, topY + 0.8, 0)
	pole.Parent = model
	local bulb = newPart("AntennaBulb", Vector3.new(0.8, 0.8, 0.8), def.accentColor)
	bulb.Shape = Enum.PartType.Ball
	bulb.Position = Vector3.new(0, topY + 1.7, 0)
	bulb.Parent = model
end

local function buildHeadphones(model, def, topY)
	local band = newPart("Headband", Vector3.new(2.6, 0.4, 0.5), def.accentColor)
	band.Position = Vector3.new(0, topY + 0.1, 0)
	band.Parent = model
	for _, side in ipairs({ -1, 1 }) do
		local can = newPart("HeadphoneCan", Vector3.new(0.5, 1.4, 1.4), def.accentColor)
		can.Position = Vector3.new(side * 1.55, topY - 0.6, 0)
		can.Parent = model
	end
end

local function buildTopHat(model, def, topY)
	local brim = newPart("HatBrim", Vector3.new(2.6, 0.2, 2.6), def.accentColor)
	brim.Position = Vector3.new(0, topY + 0.1, 0)
	brim.Parent = model
	local crown = newPart("HatCrown", Vector3.new(1.7, 1.8, 1.7), def.accentColor)
	crown.Position = Vector3.new(0, topY + 1.1, 0)
	crown.Parent = model
end

local function buildCup(model, def, topY)
	local cup = newPart("CoffeeCup", Vector3.new(1.1, 1.4, 1.1), def.accentColor)
	cup.Shape = Enum.PartType.Cylinder
	cup.CFrame = CFrame.new(2.4, topY - 1.3, 0.8) * CFrame.Angles(0, 0, math.rad(90))
	cup.Parent = model
end

local function buildWings(model, def, topY)
	for _, side in ipairs({ -1, 1 }) do
		local wing = newPart("Wing", Vector3.new(0.25, 2.6, 2.2), def.accentColor)
		wing.Position = Vector3.new(side * 2.1, topY - 0.4, -0.2)
		wing.Parent = model
	end
end

local function buildHeadband(model, def, topY)
	local band = newPart("Headband", Vector3.new(2.9, 0.45, 2.9), def.accentColor)
	band.Position = Vector3.new(0, topY - 0.75, 0)
	band.Parent = model
end

local function buildBriefcase(model, def, topY)
	local case = newPart("Briefcase", Vector3.new(1.6, 1.1, 0.6), def.accentColor)
	case.Position = Vector3.new(2.4, topY - 2.6, 1.0)
	case.Parent = model
end

local function buildHalo(model, def, topY)
	local halo = newPart("Halo", Vector3.new(2.6, 0.25, 2.6), def.accentColor)
	halo.Shape = Enum.PartType.Cylinder
	halo.CFrame = CFrame.new(0, topY + 1.6, 0) * CFrame.Angles(0, 0, math.rad(90))
	halo.Material = Enum.Material.Neon
	halo.Parent = model
end

local function buildCrown(model, def, topY)
	local crown = newPart("Crown", Vector3.new(2.4, 0.9, 2.4), def.accentColor)
	crown.Material = Enum.Material.Neon
	crown.Position = Vector3.new(0, topY + 0.5, 0)
	crown.Parent = model
	for _, offset in ipairs({ Vector3.new(-1, topY + 1.2, -1), Vector3.new(1, topY + 1.2, -1), Vector3.new(0, topY + 1.2, 1) }) do
		local spike = newPart("CrownSpike", Vector3.new(0.5, 0.8, 0.5), def.accentColor)
		spike.Material = Enum.Material.Neon
		spike.Position = offset
		spike.Parent = model
	end
end

local function buildDisco(model, def, topY)
	local ball = newPart("DiscoBall", Vector3.new(1.9, 1.9, 1.9), def.accentColor)
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.Neon
	ball.Position = Vector3.new(0, topY + 1.3, 0)
	ball.Parent = model
end

local function buildGlasses(model, def, topY)
	local bar = newPart("Glasses", Vector3.new(2.3, 0.3, 0.25), def.accentColor)
	bar.Position = Vector3.new(0, topY - 0.4, 1.7)
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
	billboard.StudsOffset = Vector3.new(0, 7.4, 0)
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

-- A full brainrot model: body, prop, label, and the mutation's re-skin (Golden neon,
-- Diamond glass). The label rides above the tallest part, so it never sits inside the hat.
function BrainrotModel.build(def, ratePerSecond, mutation)
	local model = Instance.new("Model")
	model.Name = def.id

	local headY, faceZ = buildBody(def, model)
	local buildProp = propBuilders[def.prop]
	if buildProp then
		buildProp(model, def, headY + 0.55)
	end

	if mutation == "Golden" then
		for _, part in ipairs(model:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "Pupil" then
				part.Material = Enum.Material.Neon
				part.Color = Config.Mutation.goldenColor
			end
		end
	elseif mutation == "Diamond" then
		for _, part in ipairs(model:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "Pupil" then
				part.Material = Enum.Material.Glass
				part.Color = Config.Mutation.diamondColor
				part.Transparency = 0.15
			end
		end
	end

	-- Anchor the label on the Body and float it above the whole silhouette: StudsOffset is
	-- measured from the Body's centre, so subtract that centre from the wanted height.
	local body = model:FindFirstChild("Body")
	local topY = 0
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "Pupil" then
			topY = math.max(topY, part.Position.Y + part.Size.Y / 2)
		end
	end
	local label = BrainrotModel.buildLabel(def, ratePerSecond, mutation)
	label.StudsOffset = Vector3.new(0, topY + 1.1 - body.Position.Y, 0)
	label.Adornee = body
	label.Parent = model

	model.PrimaryPart = model:FindFirstChild("Body")
	return model
end

return BrainrotModel
