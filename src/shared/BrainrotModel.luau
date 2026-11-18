-- Turns a BrainrotDefs spec into a 3D Model made only of Parts, welded to one
-- root, with a face, accessories and a BillboardGui that reads
-- NAME / RARITY / $ per second. No uploaded assets: everything is geometry.
--
-- Cylinder convention: a spec writes a cylinder's size as
-- (diameter, length, diameter) and it is built vertical; add a rotation to lay
-- it down. Blocks, balls and wedges use plain (x, y, z) sizes.
--
-- Facing convention: every character's face sits on its local +Z side. Build
-- with BrainrotModel.FacingCFrame(position, front) so the face points along
-- `front`; Roblox's own CFrame.lookAt points -Z at the target, which would
-- turn every character's back to the camera.

local BrainrotDefs = require(script.Parent.BrainrotDefs)
local Format = require(script.Parent.Format)

local BrainrotModel = {}

-- A CFrame at `position` whose local +Z axis points along `front` (the way a
-- spec's face looks), falling back to +Z when `front` is zero.
function BrainrotModel.FacingCFrame(position, front)
	if front.Magnitude < 0.001 then
		return CFrame.new(position)
	end
	return CFrame.lookAt(position, position - front.Unit)
end

local PART_SHAPES = {
	Block = Enum.PartType.Block,
	Ball = Enum.PartType.Ball,
	Cylinder = Enum.PartType.Cylinder,
}

local function orientedCFrame(position, rotation)
	return CFrame.new(position) * CFrame.Angles(
		math.rad(rotation.X),
		math.rad(rotation.Y),
		math.rad(rotation.Z)
	)
end

-- A wedge is its own class in Roblox, not a Part shape, so it is built
-- separately from the other primitives.
local function newWedge(size, color, position, rotation)
	local part = Instance.new("WedgePart")
	part.Name = "Wedge"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Size = size
	part.CFrame = orientedCFrame(position, rotation or Vector3.zero)
	return part
end

local function newPart(name, shape, size, color, position, rotation)
	if shape == "Wedge" then
		local wedge = newWedge(size, color, position, rotation)
		wedge.Name = name
		return wedge
	end
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape == "Cylinder" then
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(size.Y, size.X, size.Z)
		part.CFrame = orientedCFrame(position, rotation) * CFrame.Angles(0, 0, math.rad(90))
	else
		part.Shape = PART_SHAPES[shape] or Enum.PartType.Block
		part.Size = size
		part.CFrame = orientedCFrame(position, rotation or Vector3.zero)
	end
	return part
end

local function weldTo(part, root)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

-- A thin block whose flat face points along `forward`, used for facial
-- features so they always sit proud of the head.
local function facePlate(name, size, color, position, forward)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Size = Vector3.new(size.X, size.Y, size.Z)
	part.CFrame = CFrame.lookAt(position, position - forward)
	return part
end

local function addFace(model, def)
	local head = def.head
	local face = def.face
	local forward = def.faceForward or Vector3.new(0, 0, 1)
	local headCenter = head.offset
	local halfDepth = (head.size.X * math.abs(forward.X) + head.size.Y * math.abs(forward.Y) + head.size.Z * math.abs(forward.Z)) * 0.5
	local surface = headCenter + forward * (halfDepth + 0.28)
	local plateWidth = face.size.X
	local plateHeight = face.size.Y

	local plate = facePlate("Face", Vector3.new(plateWidth, plateHeight, 0.22), def.faceColor or Color3.fromRGB(255, 246, 226), surface, forward)
	plate.Parent = model
	weldTo(plate, model.PrimaryPart)

	local eyeSize = math.min(plateWidth, plateHeight) * 0.24
	local eyeGap = plateWidth * 0.22
	local eyeLift = plateHeight * 0.12
	local right = forward:Cross(Vector3.yAxis)
	if right.Magnitude < 0.01 then
		right = Vector3.xAxis
	end
	right = right.Unit

	for _, side in ipairs({ -1, 1 }) do
		local eyePos = surface + forward * 0.14 + right * (eyeGap * side) + Vector3.new(0, eyeLift, 0)
		local eye = facePlate("Eye", Vector3.new(eyeSize, eyeSize, 0.18), Color3.fromRGB(252, 253, 255), eyePos, forward)
		eye.Parent = model
		weldTo(eye, model.PrimaryPart)
		local pupilPos = eyePos + forward * 0.12 + right * (eyeSize * 0.12 * side)
		local pupil = facePlate("Pupil", Vector3.new(eyeSize * 0.46, eyeSize * 0.46, 0.12), Color3.fromRGB(28, 26, 34), pupilPos, forward)
		pupil.Parent = model
		weldTo(pupil, model.PrimaryPart)
	end

	local mouthPos = surface + forward * 0.14 + Vector3.new(0, -plateHeight * 0.24, 0)
	local mouth = facePlate("Mouth", Vector3.new(plateWidth * 0.4, math.max(0.16, plateHeight * 0.09), 0.14), def.mouthColor or Color3.fromRGB(92, 54, 50), mouthPos, forward)
	mouth.Parent = model
	weldTo(mouth, model.PrimaryPart)
end

local function addLabel(model, def, mutation, rate, topY)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(230, 70)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 130
	billboard.LightInfluence = 0
	billboard.Adornee = model.PrimaryPart
	billboard.Parent = model.PrimaryPart

	-- The card floats just above the character's own highest part, so small
	-- characters keep a readable label and tall ones do not lose it.
	local lift = math.max(6.8, (topY or 4) + 3.2)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, lift, 0)

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel = 0
	card.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = BrainrotDefs.RarityColor[def.rarity] or Color3.fromRGB(235, 235, 235)
	stroke.Thickness = 2
	stroke.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = card

	local grid = Instance.new("Frame")
	grid.Name = "Grid"
	grid.Size = UDim2.fromScale(1, 1)
	grid.BackgroundTransparency = 1
	grid.Parent = card
	local rows = Instance.new("UIListLayout")
	rows.FillDirection = Enum.FillDirection.Vertical
	rows.Padding = UDim.new(0, 1)
	rows.SortOrder = Enum.SortOrder.LayoutOrder
	rows.Parent = grid

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.LayoutOrder = 1
	title.Size = UDim2.new(1, 0, 0.36, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = def.name
	title.Parent = grid
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 1
	titleStroke.Parent = title

	local row = Instance.new("Frame")
	row.Name = "Meta"
	row.LayoutOrder = 2
	row.Size = UDim2.new(1, 0, 0.30, 0)
	row.BackgroundTransparency = 1
	row.Parent = grid

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Size = UDim2.new(0.55, 0, 1, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.GothamSemibold
	rarityLabel.TextScaled = true
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
	rarityLabel.TextColor3 = BrainrotDefs.RarityColor[def.rarity] or Color3.fromRGB(235, 235, 235)
	rarityLabel.Text = def.rarity
	rarityLabel.Parent = row

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.Size = UDim2.new(0.45, 0, 1, 0)
	rateLabel.Position = UDim2.new(0.55, 0, 0, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.TextScaled = true
	rateLabel.TextXAlignment = Enum.TextXAlignment.Right
	rateLabel.TextColor3 = Color3.fromRGB(126, 255, 173)
	rateLabel.Text = Format.Rate(rate)
	rateLabel.Parent = row

	local mutationLabel = Instance.new("TextLabel")
	mutationLabel.Name = "Mutation"
	mutationLabel.LayoutOrder = 3
	mutationLabel.Size = UDim2.new(1, 0, 0.30, 0)
	mutationLabel.BackgroundTransparency = 1
	mutationLabel.Font = Enum.Font.GothamBold
	mutationLabel.TextScaled = true
	mutationLabel.Text = ""
	if mutation then
		local info = BrainrotDefs.Mutations[mutation]
		mutationLabel.Text = string.upper(mutation) .. "  x" .. tostring(info.rateMultiplier)
		mutationLabel.TextColor3 = info.sparkle
	else
		mutationLabel.Visible = false
		title.Size = UDim2.new(1, 0, 0.45, 0)
		row.Size = UDim2.new(1, 0, 0.42, 0)
	end
	mutationLabel.Parent = grid

	return billboard
end

-- Adds or replaces a price strip at the bottom of the floating card. Used on
-- conveyor offers so the cost is readable from across the runway.
function BrainrotModel.SetLabelPrice(model, text)
	local root = model.PrimaryPart
	local label = root and root:FindFirstChild("Label")
	local card = label and label:FindFirstChild("Card")
	local grid = card and card:FindFirstChild("Grid")
	if not grid then
		return
	end
	local existing = grid:FindFirstChild("Price")
	if existing then
		existing.Text = text
		return
	end
	local price = Instance.new("TextLabel")
	price.Name = "Price"
	price.LayoutOrder = 4
	price.Size = UDim2.new(1, 0, 0.28, 0)
	price.BackgroundColor3 = Color3.fromRGB(46, 122, 92)
	price.BackgroundTransparency = 0.15
	price.BorderSizePixel = 0
	price.Font = Enum.Font.GothamBlack
	price.TextScaled = true
	price.TextColor3 = Color3.fromRGB(220, 255, 236)
	price.Text = text
	price.Parent = grid
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = price
	card.Size = UDim2.fromOffset(230, 96)
	label.Size = UDim2.fromOffset(230, 96)
end

local function addAura(model, def, mutation)
	local color = BrainrotDefs.RarityColor[def.rarity] or Color3.fromRGB(255, 255, 255)
	local mutationInfo = mutation and BrainrotDefs.Mutations[mutation] or nil
	local glow = BrainrotDefs.RarityGlow[def.rarity] or 0

	local aura = Instance.new("Part")
	aura.Name = "Aura"
	aura.Shape = Enum.PartType.Ball
	aura.Size = Vector3.new(5.4, 5.4, 5.4)
	aura.CFrame = model.PrimaryPart.CFrame
	aura.Anchored = true
	aura.CanCollide = false
	aura.CanQuery = false
	aura.CanTouch = false
	aura.Material = Enum.Material.ForceField
	aura.Color = mutationInfo and mutationInfo.tint or color
	aura.Transparency = 0.9 - math.clamp(glow * 0.012, 0, 0.16) - (mutationInfo and 0.06 or 0)
	aura.Parent = model
	weldTo(aura, model.PrimaryPart)

	if mutationInfo then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "Sparkles"
		sparkles.Color = ColorSequence.new(mutationInfo.sparkle)
		sparkles.LightEmission = 1
		sparkles.Rate = 22
		sparkles.Lifetime = NumberRange.new(0.5, 1.2)
		sparkles.Speed = NumberRange.new(1.0, 2.8)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		})
		sparkles.Parent = aura
	end
end

-- Builds the model standing at `cframe`. Returns the Model (PrimaryPart is
-- the root body part) and the effective money-per-second rate.
function BrainrotModel.Build(def, mutation, cframe, rateOverride)
	local mutationInfo = mutation and BrainrotDefs.Mutations[mutation] or nil
	local rate = rateOverride or (def.rate * (mutationInfo and mutationInfo.rateMultiplier or 1))

	local model = Instance.new("Model")
	model.Name = def.name .. ((mutation and (" " .. mutation)) or "")

	local bodySpec = def.body
	local root = newPart("Root", bodySpec.shape, bodySpec.size, bodySpec.color, Vector3.zero, def.rotateBody or Vector3.zero)
	if mutationInfo then
		root.Color = root.Color:Lerp(mutationInfo.tint, 0.55)
		root.Material = Enum.Material.Neon
		root.Reflectance = 0.12
	end
	root.Parent = model
	model.PrimaryPart = root

	local headSpec = def.head
	if headSpec then
		local head = newPart("Head", headSpec.shape, headSpec.size, headSpec.color, headSpec.offset, headSpec.rotation or Vector3.zero)
		if mutationInfo then
			head.Color = head.Color:Lerp(mutationInfo.tint, 0.5)
		end
		head.Parent = model
		weldTo(head, root)
	end

	for _, spec in ipairs(def.parts or {}) do
		local part = newPart(spec.name or "Detail", spec.shape, spec.size, spec.color, spec.offset, spec.rotation or Vector3.zero)
		if spec.material then
			part.Material = spec.material
		end
		if mutationInfo then
			part.Color = part.Color:Lerp(mutationInfo.tint, 0.35)
		end
		part.Parent = model
		weldTo(part, root)
	end

	if def.face then
		addFace(model, def)
	end

	-- Where the body's lowest and highest points sit, measured before the aura
	-- (a sphere around the whole character) is added, so the aura can neither
	-- float the model above the ground nor push the label out of reach.
	local boundsCFrame, boundsSize = model:GetBoundingBox()
	local lowest = boundsCFrame.Y - boundsSize.Y * 0.5
	local topY = boundsCFrame.Y + boundsSize.Y * 0.5

	addAura(model, def, mutation)
	addLabel(model, def, mutation, rate, topY)

	-- `cframe` marks where the character's feet go.
	model:PivotTo(cframe * CFrame.new(0, -lowest, 0))

	model:SetAttribute("BrainrotId", def.id)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Rate", rate)
	if mutation then
		model:SetAttribute("Mutation", mutation)
	end
	return model, rate
end

function BrainrotModel.SetLabelRate(model, rate)
	local root = model.PrimaryPart
	local label = root and root:FindFirstChild("Label")
	local card = label and label:FindFirstChild("Card")
	local grid = card and card:FindFirstChild("Grid")
	local row = grid and grid:FindFirstChild("Meta")
	local rateLabel = row and row:FindFirstChild("Rate")
	if rateLabel then
		rateLabel.Text = Format.Rate(rate)
	end
end

return BrainrotModel
