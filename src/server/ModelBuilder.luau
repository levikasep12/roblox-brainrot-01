-- ModelBuilder: turns a BrainrotDefs entry into a 3D model made only of parts.
-- No uploaded meshes or decals: every creature is boxes, wedges and spheres, so
-- it renders for any reviewer. Each model carries one small BillboardGui label
-- (name / rarity / $ per second) with AlwaysOnTop = false so nearer labels hide
-- farther ones instead of stacking into unreadable mush.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local BrainrotDefs = require(Shared:WaitForChild("BrainrotDefs"))
local Mutations = require(Shared:WaitForChild("Mutations"))

local ModelBuilder = {}

local NAME_FONT = Enum.Font.GothamBold
local LABEL_SIZE = Vector2.new(150, 46)

local function part(parent: Instance, size: Vector3, color: Color3, position: Vector3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Position = position
	p.Parent = parent
	return p
end

local function eye(parent: Part, x: number, y: number, z: number, radius: number)
	local e = part(parent, Vector3.new(radius, radius, radius * 0.55), Color3.fromRGB(24, 24, 32), Vector3.zero)
	e.Shape = Enum.PartType.Ball
	e.CFrame = parent.CFrame * CFrame.new(x, y, z)
	e.Parent = parent
end

-- Each recipe builds around the model's origin (feet at y=0) and returns the
-- visual height so callers can hang the label above it.
local recipes = {}

function recipes.cucumber(root: Part, def: any)
	local body = part(root, Vector3.new(1.6, 5.2, 1.6), def.bodyColor, Vector3.new(0, 2.6, 0), Enum.PartType.Cylinder)
	body.CFrame = CFrame.new(Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part(root, Vector3.new(2.1, 0.5, 2.1), Color3.fromRGB(242, 214, 72), Vector3.new(0, 5.3, 0))
	part(root, Vector3.new(0.5, 0.8, 0.5), Color3.fromRGB(242, 214, 72), Vector3.new(0, 5.8, 0))
	part(root, Vector3.new(0.34, 1.1, 0.34), Color3.fromRGB(40, 40, 44), Vector3.new(-0.42, 3.7, -0.82))
	part(root, Vector3.new(0.34, 1.1, 0.34), Color3.fromRGB(40, 40, 44), Vector3.new(0.42, 3.7, -0.82))
	return 6.4
end

function recipes.capybara(root: Part, def: any)
	part(root, Vector3.new(2.6, 1.9, 4.0), def.bodyColor, Vector3.new(0, 1.8, 0))
	part(root, Vector3.new(2.0, 1.6, 1.8), def.bodyColor, Vector3.new(0, 2.1, -2.2))
	part(root, Vector3.new(2.2, 0.9, 0.5), Color3.fromRGB(214, 176, 138), Vector3.new(0, 1.5, -3.1))
	part(root, Vector3.new(2.9, 0.28, 2.4), Color3.fromRGB(248, 248, 248), Vector3.new(0, 2.95, -0.7))
	local hat = part(root, Vector3.new(1.7, 0.9, 1.7), Color3.fromRGB(248, 248, 248), Vector3.new(0, 3.5, -0.7))
	hat.Shape = Enum.PartType.Cylinder
	hat.CFrame = CFrame.new(Vector3.new(0, 3.6, -0.7)) * CFrame.Angles(0, 0, math.rad(90))
	for _, z in ipairs({ -1.1, 1.1 }) do
		part(root, Vector3.new(0.5, 1.4, 0.5), def.bodyColor, Vector3.new(-0.95, 0.7, z))
		part(root, Vector3.new(0.5, 1.4, 0.5), def.bodyColor, Vector3.new(0.95, 0.7, z))
	end
	part(root, Vector3.new(0.3, 0.35, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(-0.55, 2.4, -3.15))
	part(root, Vector3.new(0.3, 0.35, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(0.55, 2.4, -3.15))
	return 4.2
end

function recipes.toilet(root: Part, def: any)
	part(root, Vector3.new(2.2, 1.5, 2.2), def.bodyColor, Vector3.new(0, 0.75, 0))
	part(root, Vector3.new(1.8, 0.4, 1.8), Color3.fromRGB(126, 200, 255), Vector3.new(0, 1.55, 0))
	local head = part(root, Vector3.new(1.7, 1.7, 1.7), def.bodyColor, Vector3.new(0, 3.0, 0), Enum.PartType.Ball)
	head.Color = Color3.fromRGB(240, 226, 206)
	part(root, Vector3.new(2.4, 1.6, 1.0), def.bodyColor, Vector3.new(0, 2.2, 1.4))
	part(root, Vector3.new(0.22, 1.3, 0.22), Color3.fromRGB(90, 90, 100), Vector3.new(-0.5, 4.2, -0.4))
	part(root, Vector3.new(0.22, 1.3, 0.22), Color3.fromRGB(90, 90, 100), Vector3.new(0.5, 4.2, -0.4))
	part(root, Vector3.new(1.5, 0.3, 0.3), Color3.fromRGB(90, 90, 100), Vector3.new(0, 4.85, -0.4))
	part(root, Vector3.new(0.34, 0.34, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(-0.4, 3.2, -0.85))
	part(root, Vector3.new(0.34, 0.34, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(0.4, 3.2, -0.85))
	return 5.4
end

function recipes.durian(root: Part, def: any)
	local body = part(root, Vector3.new(3.2, 3.2, 3.2), def.bodyColor, Vector3.new(0, 2.1, 0), Enum.PartType.Ball)
	body.Color = def.bodyColor
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		local spike = part(root, Vector3.new(0.5, 0.9, 0.5), def.bodyColor, Vector3.zero)
		spike.CFrame = CFrame.new(Vector3.new(math.cos(angle) * 1.55, 2.1 + (i % 2) * 1.1, math.sin(angle) * 1.55))
			* CFrame.Angles(math.rad(90), angle, 0)
	end
	part(root, Vector3.new(3.6, 0.3, 3.6), Color3.fromRGB(30, 30, 36), Vector3.new(0, 4.05, 0))
	local deck = part(root, Vector3.new(1.5, 0.22, 1.5), Color3.fromRGB(60, 60, 72), Vector3.new(0, 4.3, 0))
	deck.Shape = Enum.PartType.Cylinder
	deck.CFrame = CFrame.new(Vector3.new(0, 4.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part(root, Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(255, 96, 156), Vector3.new(0, 4.3, 0))
	part(root, Vector3.new(0.4, 0.4, 0.25), Color3.fromRGB(26, 26, 32), Vector3.new(-0.62, 2.4, -1.5))
	part(root, Vector3.new(0.4, 0.4, 0.25), Color3.fromRGB(26, 26, 32), Vector3.new(0.62, 2.4, -1.5))
	return 5.2
end

function recipes.flamingo(root: Part, def: any)
	part(root, Vector3.new(1.9, 1.7, 2.6), def.bodyColor, Vector3.new(0, 2.6, 0))
	part(root, Vector3.new(2.0, 0.3, 2.2), Color3.fromRGB(255, 96, 140), Vector3.new(0, 3.5, -0.3))
	local neck = part(root, Vector3.new(0.5, 3.0, 0.5), def.bodyColor, Vector3.new(0, 4.5, -1.0))
	neck.CFrame = CFrame.new(Vector3.new(0, 4.4, -1.15)) * CFrame.Angles(math.rad(-16), 0, 0)
	local head = part(root, Vector3.new(1.0, 0.9, 1.4), def.bodyColor, Vector3.new(0, 5.9, -1.7))
	head.CFrame = CFrame.new(Vector3.new(0, 5.9, -1.7)) * CFrame.Angles(math.rad(-14), 0, 0)
	part(root, Vector3.new(0.5, 0.34, 0.9), Color3.fromRGB(255, 232, 120), Vector3.new(0, 5.73, -2.55))
	part(root, Vector3.new(0.3, 2.6, 0.3), Color3.fromRGB(255, 128, 164), Vector3.new(-0.4, 1.3, 0.2))
	part(root, Vector3.new(0.3, 0.3, 1.0), Color3.fromRGB(255, 128, 164), Vector3.new(-0.4, 0.15, 0.5))
	part(root, Vector3.new(0.3, 1.0, 0.3), Color3.fromRGB(255, 128, 164), Vector3.new(0.5, 0.5, 0.3))
	part(root, Vector3.new(0.3, 0.25, 0.25), Color3.fromRGB(26, 26, 32), Vector3.new(-0.3, 6.0, -2.15))
	part(root, Vector3.new(0.3, 0.25, 0.25), Color3.fromRGB(26, 26, 32), Vector3.new(0.3, 6.0, -2.15))
	return 6.6
end

function recipes.rat(root: Part, def: any)
	part(root, Vector3.new(1.7, 1.4, 2.8), def.bodyColor, Vector3.new(0, 1.3, 0))
	part(root, Vector3.new(1.5, 1.3, 1.4), def.bodyColor, Vector3.new(0, 1.5, -1.9))
	part(root, Vector3.new(0.7, 0.25, 0.8), Color3.fromRGB(255, 154, 166), Vector3.new(0, 1.05, -2.6))
	part(root, Vector3.new(1.2, 1.2, 1.2), Color3.fromRGB(255, 196, 64), Vector3.new(0, 1.0, 0.6), Enum.PartType.Ball)
	local ear = part(root, Vector3.new(1.1, 0.14, 1.1), Color3.fromRGB(255, 154, 166), Vector3.new(-0.55, 2.4, -1.8))
	ear.Shape = Enum.PartType.Cylinder
	ear.CFrame = CFrame.new(Vector3.new(-0.55, 2.4, -1.8)) * CFrame.Angles(0, 0, math.rad(90))
	ear = part(root, Vector3.new(1.1, 0.14, 1.1), Color3.fromRGB(255, 154, 166), Vector3.new(0.55, 2.4, -1.8))
	ear.CFrame = CFrame.new(Vector3.new(0.55, 2.4, -1.8)) * CFrame.Angles(0, 0, math.rad(90))
	local tail = part(root, Vector3.new(0.16, 0.16, 3.0), Color3.fromRGB(230, 190, 200), Vector3.new(0, 1.5, 2.6))
	tail.CFrame = CFrame.new(Vector3.new(0, 1.7, 2.6)) * CFrame.Angles(math.rad(24), 0, 0)
	part(root, Vector3.new(0.26, 0.3, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(-0.4, 1.7, -2.5))
	part(root, Vector3.new(0.26, 0.3, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(0.4, 1.7, -2.5))
	return 3.0
end

function recipes.granny(root: Part, def: any)
	local dress = part(root, Vector3.new(2.8, 2.6, 2.4), def.bodyColor, Vector3.new(0, 1.7, 0))
	dress.Color = def.accentColor
	dress.CFrame = CFrame.new(Vector3.new(0, 1.7, 0)) * CFrame.Angles(0, 0, 0)
	local head = part(root, Vector3.new(1.8, 1.8, 1.7), def.bodyColor, Vector3.new(0, 3.9, 0), Enum.PartType.Ball)
	head.Color = Color3.fromRGB(232, 198, 152)
	local bun = part(root, Vector3.new(1.1, 1.1, 1.1), Color3.fromRGB(226, 226, 232), Vector3.new(0, 4.8, 0.7), Enum.PartType.Ball)
	bun.Color = Color3.fromRGB(228, 228, 236)
	part(root, Vector3.new(0.14, 0.16, 0.5), Color3.fromRGB(90, 90, 100), Vector3.new(-0.4, 4.25, -0.8))
	part(root, Vector3.new(0.14, 0.16, 0.5), Color3.fromRGB(90, 90, 100), Vector3.new(0.4, 4.25, -0.8))
	part(root, Vector3.new(0.9, 0.18, 0.2), Color3.fromRGB(120, 70, 70), Vector3.new(0, 3.5, -0.85))
	local cane = part(root, Vector3.new(0.14, 3.0, 0.14), Color3.fromRGB(150, 110, 70), Vector3.new(1.5, 1.5, -0.5))
	cane.CFrame = CFrame.new(Vector3.new(1.5, 1.5, -0.5)) * CFrame.Angles(math.rad(6), 0, 0)
	local frame = part(root, Vector3.new(0.16, 0.16, 2.2), Color3.fromRGB(196, 156, 78), Vector3.new(0, 2.8, -1.5))
	frame.CFrame = CFrame.new(Vector3.new(0, 2.8, -1.5)) * CFrame.Angles(math.rad(-18), 0, 0)
	return 5.4
end

function recipes.snowman(root: Part, def: any)
	part(root, Vector3.new(2.9, 2.9, 2.9), def.bodyColor, Vector3.new(0, 1.5, 0), Enum.PartType.Ball)
	part(root, Vector3.new(2.1, 2.1, 2.1), def.bodyColor, Vector3.new(0, 3.6, 0), Enum.PartType.Ball)
	local head = part(root, Vector3.new(1.6, 1.6, 1.6), def.bodyColor, Vector3.new(0, 5.4, 0), Enum.PartType.Ball)
	local hatBrim = part(root, Vector3.new(2.1, 0.2, 2.1), Color3.fromRGB(40, 40, 52), Vector3.new(0, 6.2, 0))
	hatBrim.Shape = Enum.PartType.Cylinder
	hatBrim.CFrame = CFrame.new(Vector3.new(0, 6.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part(root, Vector3.new(1.3, 1.2, 1.3), Color3.fromRGB(40, 40, 52), Vector3.new(0, 6.9, 0))
	part(root, Vector3.new(0.5, 0.5, 0.7), Color3.fromRGB(255, 148, 44), Vector3.new(0, 5.4, -0.95))
	part(root, Vector3.new(0.24, 0.24, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(-0.4, 5.7, -0.7))
	part(root, Vector3.new(0.24, 0.24, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(0.4, 5.7, -0.7))
	part(root, Vector3.new(2.1, 0.3, 0.3), Color3.fromRGB(232, 64, 72), Vector3.new(0, 4.3, 0))
	local scarf = part(root, Vector3.new(0.4, 1.4, 0.3), Color3.fromRGB(232, 64, 72), Vector3.new(0.6, 3.8, -0.8))
	scarf.CFrame = CFrame.new(Vector3.new(0.6, 3.8, -0.8)) * CFrame.Angles(math.rad(10), 0, math.rad(12))
	for _, x in ipairs({ -1.6, 1.6 }) do
		local arm = part(root, Vector3.new(2.2, 0.18, 0.18), Color3.fromRGB(120, 84, 52), Vector3.new(0, 3.7, 0))
		arm.CFrame = CFrame.new(Vector3.new(x, 3.9, 0)) * CFrame.Angles(0, 0, math.rad(x > 0 and -24 or 24))
	end
	return 7.6
end

function recipes.toaster(root: Part, def: any)
	part(root, Vector3.new(3.0, 2.0, 2.2), def.bodyColor, Vector3.new(0, 1.4, 0))
	part(root, Vector3.new(2.6, 0.25, 1.9), Color3.fromRGB(60, 60, 70), Vector3.new(0, 2.45, 0))
	local toast = part(root, Vector3.new(1.6, 1.5, 0.4), Color3.fromRGB(226, 170, 96), Vector3.new(0, 3.2, -0.3))
	toast.CFrame = CFrame.new(Vector3.new(0, 3.3, -0.3)) * CFrame.Angles(math.rad(-8), 0, 0)
	part(root, Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(255, 128, 48), Vector3.new(-1.6, 1.4, 0))
	part(root, Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(255, 128, 48), Vector3.new(1.6, 1.4, 0))
	for _, x in ipairs({ -0.6, 0.6 }) do
		local leg = part(root, Vector3.new(0.4, 0.8, 0.4), Color3.fromRGB(80, 80, 92), Vector3.new(x, 0.4, 0))
		leg.CFrame = CFrame.new(Vector3.new(x, 0.4, 0))
	end
	part(root, Vector3.new(0.34, 0.34, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(-0.6, 1.8, -1.15))
	part(root, Vector3.new(0.34, 0.34, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(0.6, 1.8, -1.15))
	local knob = part(root, Vector3.new(0.4, 0.32, 0.4), Color3.fromRGB(255, 128, 48), Vector3.new(1.1, 1.0, -1.1))
	knob.CFrame = CFrame.new(Vector3.new(1.1, 1.0, -1.1)) * CFrame.Angles(0, 0, math.rad(90))
	return 4.4
end

function recipes.monkey(root: Part, def: any)
	part(root, Vector3.new(1.9, 1.8, 2.0), def.bodyColor, Vector3.new(0, 2.4, 0))
	local head = part(root, Vector3.new(1.9, 1.9, 1.8), def.bodyColor, Vector3.new(0, 4.0, 0), Enum.PartType.Ball)
	local face = part(root, Vector3.new(1.3, 1.3, 0.5), Color3.fromRGB(232, 190, 150), Vector3.new(0, 3.9, -0.7))
	face.CFrame = CFrame.new(Vector3.new(0, 3.9, -0.95))
	local helmet = part(root, Vector3.new(2.2, 1.2, 2.2), Color3.fromRGB(246, 250, 255), Vector3.new(0, 4.8, 0), Enum.PartType.Ball)
	part(root, Vector3.new(1.9, 1.9, 1.2), Color3.fromRGB(246, 250, 255), Vector3.new(0, 4.5, 1.6))
	part(root, Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(126, 236, 255), Vector3.new(0, 5.5, -1.6))
	for _, x in ipairs({ -1.25, 1.25 }) do
		local arm = part(root, Vector3.new(0.5, 2.2, 0.5), def.bodyColor, Vector3.new(0, 2.6, 0))
		arm.CFrame = CFrame.new(Vector3.new(x, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(x > 0 and -12 or 12))
	end
	for _, x in ipairs({ -0.55, 0.55 }) do
		part(root, Vector3.new(0.55, 1.0, 0.55), def.bodyColor, Vector3.new(x, 0.6, 0))
	end
	local banana = part(root, Vector3.new(0.35, 0.35, 2.0), Color3.fromRGB(255, 226, 96), Vector3.new(1.7, 2.2, -0.4))
	banana.CFrame = CFrame.new(Vector3.new(1.7, 2.3, -0.4)) * CFrame.Angles(math.rad(30), 0, 0)
	part(root, Vector3.new(0.3, 0.34, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(-0.4, 4.0, -0.95))
	part(root, Vector3.new(0.3, 0.34, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(0.4, 4.0, -0.95))
	return 5.8
end

function recipes.cabbage(root: Part, def: any)
	for i = 0, 5 do
		local angle = (i / 6) * math.pi * 2
		local leaf = part(root, Vector3.new(2.6, 2.4, 0.5), def.bodyColor, Vector3.zero)
		leaf.CFrame = CFrame.new(Vector3.new(math.cos(angle) * 0.85, 1.6, math.sin(angle) * 0.85))
			* CFrame.Angles(math.rad(12), angle, math.rad(18))
	end
	part(root, Vector3.new(1.6, 1.6, 1.6), Color3.fromRGB(180, 230, 150), Vector3.new(0, 3.0, 0), Enum.PartType.Ball)
	local halo = part(root, Vector3.new(2.6, 0.16, 2.6), Color3.fromRGB(122, 226, 255), Vector3.new(0, 4.4, 0))
	halo.Shape = Enum.PartType.Cylinder
	halo.CFrame = CFrame.new(Vector3.new(0, 4.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	part(root, Vector3.new(0.3, 0.34, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(-0.38, 3.1, -0.72))
	part(root, Vector3.new(0.3, 0.34, 0.2), Color3.fromRGB(26, 26, 32), Vector3.new(0.38, 3.1, -0.72))
	return 4.9
end

--- Builds one brainrot model. Returns the Model; the model's PrimaryPart is the
--- invisible root the walk animation moves, and a "Label" BillboardGui is added.
function ModelBuilder.build(defId: string, mutationId: string?)
	local def = BrainrotDefs.get(defId)
	if not def then
		error("unknown brainrot " .. tostring(defId))
	end
	local mutation = Mutations.get(mutationId)

	local model = Instance.new("Model")
	model.Name = def.id

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Anchored = true
	root.CFrame = CFrame.new(0, 0, 0)
	root.Parent = model
	model.PrimaryPart = root

	local recipe = recipes[def.shape]
	if not recipe then
		error("no recipe for shape " .. tostring(def.shape))
	end
	local height = recipe(root, def)
	model:SetAttribute("LabelHeight", height)

	if mutation.tint then
		for _, child in ipairs(model:GetDescendants()) do
			if child:IsA("BasePart") and child ~= root then
				child.Color = child.Color:Lerp(mutation.tint, 0.55)
				child.Material = Enum.Material.Neon
			end
		end
	end

	local labelBillboard = Instance.new("BillboardGui")
	labelBillboard.Name = "Label"
	labelBillboard.Size = UDim2.fromOffset(LABEL_SIZE.X, LABEL_SIZE.Y)
	labelBillboard.StudsOffsetWorldSpace = Vector3.new(0, height + 1.0, 0)
	labelBillboard.AlwaysOnTop = false
	labelBillboard.MaxDistance = 90
	labelBillboard.LightInfluence = 0
	labelBillboard.Adornee = root
	labelBillboard.Parent = root

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
	frame.BackgroundTransparency = 0.18
	frame.BorderSizePixel = 0
	frame.Parent = labelBillboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = BrainrotDefs.RarityColors[def.rarity] or Color3.fromRGB(200, 200, 200)
	stroke.Thickness = 1
	stroke.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(4, 2)
	nameLabel.Size = UDim2.new(1, -8, 0, 17)
	nameLabel.Font = NAME_FONT
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextColor3 = Color3.fromRGB(242, 244, 250)
	nameLabel.Text = def.name
	nameLabel.Parent = frame

	local meta = Instance.new("TextLabel")
	meta.Name = "Meta"
	meta.BackgroundTransparency = 1
	meta.Position = UDim2.fromOffset(4, 19)
	meta.Size = UDim2.new(1, -8, 0, 12)
	meta.Font = Enum.Font.GothamMedium
	meta.TextSize = 10
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.TextColor3 = BrainrotDefs.RarityColors[def.rarity] or Color3.fromRGB(200, 200, 200)
	meta.Text = def.rarity .. (mutation.label ~= "" and (" · " .. mutation.label) or "")
	meta.Parent = frame

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.BackgroundTransparency = 1
	rateLabel.Position = UDim2.fromOffset(4, 30)
	rateLabel.Size = UDim2.new(1, -8, 0, 14)
	rateLabel.Font = NAME_FONT
	rateLabel.TextSize = 11
	rateLabel.TextXAlignment = Enum.TextXAlignment.Left
	rateLabel.TextColor3 = Color3.fromRGB(120, 240, 150)
	rateLabel.Text = "$" .. tostring(math.floor(def.rate * mutation.rateMultiplier)) .. "/sec"
	rateLabel.Parent = frame

	return model, def, mutation
end

return ModelBuilder
