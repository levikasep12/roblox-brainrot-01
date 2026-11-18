-- Builds every brainrot out of plain Parts (no uploaded meshes) and hangs a
-- BillboardGui above it with name, rarity and money per second.

local Format = require(script.Parent.Format)
local BrainrotDefs = require(script.Parent.BrainrotDefs)

local BrainrotModel = {}

local SHAPE = {
	Block = Enum.PartType.Block,
	Ball = Enum.PartType.Ball,
	Cylinder = Enum.PartType.Cylinder,
}

local function newPart(model: Model, name: string, size: Vector3, color: Color3, offset: Vector3, options: any?)
	options = options or {}
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Shape = SHAPE[options.shape or "Block"] or Enum.PartType.Block
	part.Material = options.material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Transparency = options.transparency or 0
	local rotation = options.rotation or CFrame.identity
	part.CFrame = CFrame.new(offset) * rotation
	part.Parent = model
	return part
end

local function newRoot(model: Model)
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1.4, 0.2, 1.4)
	root.CFrame = CFrame.new(0, 0.1, 0)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Parent = model
	model.PrimaryPart = root
	return root
end

local function eyes(model: Model, offset: Vector3, spread: number, size: number, pupil: number)
	for side = -1, 1, 2 do
		newPart(model, "Eye", Vector3.new(size, size, size * 0.7), Color3.fromRGB(250, 250, 250), offset + Vector3.new(spread * side, 0, 0), { shape = "Ball" })
		newPart(model, "Pupil", Vector3.new(pupil, pupil, pupil), Color3.fromRGB(18, 18, 22), offset + Vector3.new(spread * side, 0, -size * 0.34), { shape = "Ball" })
	end
end

local builders = {}

function builders.capybaraChef(model: Model)
	local fur = Color3.fromRGB(154, 118, 82)
	local dark = Color3.fromRGB(104, 76, 50)
	newPart(model, "Body", Vector3.new(2.8, 2.4, 2.2), fur, Vector3.new(0, 2.2, 0), { rotation = CFrame.Angles(0.06, 0, 0) })
	newPart(model, "Belly", Vector3.new(2.2, 1.9, 0.5), Color3.fromRGB(206, 178, 140), Vector3.new(0, 2.1, 0.95))
	newPart(model, "Head", Vector3.new(2.4, 2.1, 2.2), fur, Vector3.new(0, 4.1, 0.4))
	newPart(model, "Snout", Vector3.new(1.5, 0.9, 0.9), dark, Vector3.new(0, 3.85, 1.55))
	newPart(model, "Nose", Vector3.new(0.6, 0.34, 0.3), Color3.fromRGB(44, 32, 24), Vector3.new(0, 4.05, 2.02))
	for side = -1, 1, 2 do
		newPart(model, "Ear", Vector3.new(0.5, 0.5, 0.3), dark, Vector3.new(0.75 * side, 5.0, 0.1), { shape = "Ball" })
		newPart(model, "Arm", Vector3.new(0.55, 1.7, 0.55), fur, Vector3.new(1.55 * side, 2.1, 0.2), { rotation = CFrame.Angles(0, 0, math.rad(10 * side)) })
		newPart(model, "Foot", Vector3.new(0.9, 0.5, 1.2), dark, Vector3.new(0.8 * side, 0.35, 0.5))
	end
	eyes(model, Vector3.new(0, 4.3, 1.48), 0.6, 0.44, 0.2)
	newPart(model, "HatBrim", Vector3.new(2.0, 0.18, 2.0), Color3.fromRGB(245, 245, 245), Vector3.new(0, 5.25, 0.35), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "HatTop", Vector3.new(1.6, 1.1, 1.6), Color3.fromRGB(250, 250, 250), Vector3.new(0, 5.85, 0.35), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "Whisk", Vector3.new(0.1, 1.9, 0.1), Color3.fromRGB(220, 220, 225), Vector3.new(1.75, 3.0, 0.9), { rotation = CFrame.Angles(0.2, 0, math.rad(-18)) })
	newPart(model, "WhiskWire", Vector3.new(0.55, 0.8, 0.55), Color3.fromRGB(210, 210, 215), Vector3.new(2.2, 3.85, 0.95), { shape = "Ball", transparency = 0.35 })
end

function builders.durianDj(model: Model)
	local rind = Color3.fromRGB(178, 196, 72)
	local flesh = Color3.fromRGB(245, 216, 96)
	newPart(model, "Body", Vector3.new(3.0, 2.8, 2.8), rind, Vector3.new(0, 2.1, 0), { shape = "Ball" })
	newPart(model, "Face", Vector3.new(2.0, 1.5, 0.6), flesh, Vector3.new(0, 2.15, 1.15))
	for i = 0, 7 do
		local angle = i / 8 * math.pi * 2
		local spike = newPart(model, "Spike", Vector3.new(0.34, 1.0, 0.34), Color3.fromRGB(146, 164, 58), Vector3.new(math.cos(angle) * 1.45, 2.1, math.sin(angle) * 1.45), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(-angle, 0, 0) })
		spike.Size = Vector3.new(0.34, 1.0, 0.34)
	end
	newPart(model, "Headphones", Vector3.new(3.5, 0.45, 0.6), Color3.fromRGB(32, 32, 40), Vector3.new(0, 3.9, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	for side = -1, 1, 2 do
		newPart(model, "EarCup", Vector3.new(0.75, 1.0, 1.0), Color3.fromRGB(255, 92, 92), Vector3.new(1.6 * side, 3.05, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
		newPart(model, "Sneaker", Vector3.new(1.0, 0.55, 1.6), Color3.fromRGB(240, 240, 245), Vector3.new(0.85 * side, 0.3, 0.4))
	end
	eyes(model, Vector3.new(0, 2.35, 1.42), 0.55, 0.5, 0.22)
	newPart(model, "Grill", Vector3.new(1.25, 0.28, 0.2), Color3.fromRGB(255, 255, 255), Vector3.new(0, 1.6, 1.46))
	newPart(model, "Deck", Vector3.new(1.7, 0.24, 1.2), Color3.fromRGB(44, 44, 54), Vector3.new(0, 0.75, 1.9), { rotation = CFrame.Angles(-0.5, 0, 0) })
	newPart(model, "Vinyl", Vector3.new(0.9, 0.12, 0.9), Color3.fromRGB(22, 22, 26), Vector3.new(0, 0.9, 1.95), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
end

function builders.skibidiToaster(model: Model)
	local steel = Color3.fromRGB(198, 206, 216)
	local bread = Color3.fromRGB(226, 174, 96)
	newPart(model, "Body", Vector3.new(3.2, 2.3, 2.2), steel, Vector3.new(0, 1.5, 0))
	newPart(model, "Top", Vector3.new(3.0, 0.3, 2.0), Color3.fromRGB(226, 232, 240), Vector3.new(0, 2.7, 0))
	newPart(model, "Slot", Vector3.new(1.8, 0.18, 0.5), Color3.fromRGB(40, 42, 48), Vector3.new(0, 2.86, 0))
	for i = -1, 1, 2 do
		newPart(model, "Toast", Vector3.new(1.3, 1.2, 0.28), bread, Vector3.new(0.65 * i, 3.4, 0), { rotation = CFrame.Angles(0, 0, math.rad(6 * i)) })
		newPart(model, "Crust", Vector3.new(1.3, 1.2, 0.1), Color3.fromRGB(186, 130, 60), Vector3.new(0.65 * i, 3.4, -0.12), { rotation = CFrame.Angles(0, 0, math.rad(6 * i)) })
	end
	newPart(model, "Mouth", Vector3.new(1.5, 0.6, 0.2), Color3.fromRGB(30, 30, 36), Vector3.new(0, 1.5, 1.12))
	newPart(model, "Tongue", Vector3.new(0.9, 0.25, 0.25), Color3.fromRGB(240, 110, 130), Vector3.new(0, 1.35, 1.18))
	eyes(model, Vector3.new(0, 2.15, 1.1), 0.62, 0.55, 0.24)
	for side = -1, 1, 2 do
		newPart(model, "Wheel", Vector3.new(0.7, 0.3, 0.7), Color3.fromRGB(32, 32, 38), Vector3.new(1.15 * side, 0.3, 0.6), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
		newPart(model, "Knob", Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(255, 96, 96), Vector3.new(1.55 * side, 1.6, 0.1), { shape = "Ball" })
	end
	newPart(model, "Lever", Vector3.new(0.16, 0.9, 0.16), Color3.fromRGB(120, 126, 136), Vector3.new(1.2, 3.1, 0.6))
	newPart(model, "LeverKnob", Vector3.new(0.38, 0.38, 0.38), Color3.fromRGB(255, 196, 64), Vector3.new(1.2, 3.6, 0.6), { shape = "Ball" })
end

function builders.cucumberCowboy(model: Model)
	local green = Color3.fromRGB(96, 176, 92)
	local darkGreen = Color3.fromRGB(66, 136, 66)
	newPart(model, "Body", Vector3.new(1.7, 3.4, 1.7), green, Vector3.new(0, 2.1, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "Head", Vector3.new(1.55, 1.6, 1.55), green, Vector3.new(0, 4.2, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	for i = 0, 5 do
		local angle = i / 6 * math.pi * 2
		newPart(model, "Bump", Vector3.new(0.36, 0.36, 0.36), darkGreen, Vector3.new(math.cos(angle) * 0.6, 2.7 + (i % 3) * 0.7, math.sin(angle) * 0.6), { shape = "Ball" })
	end
	newPart(model, "HatBrim", Vector3.new(2.6, 0.18, 2.6), Color3.fromRGB(152, 108, 62), Vector3.new(0, 4.95, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "HatTop", Vector3.new(1.5, 1.0, 1.5), Color3.fromRGB(122, 86, 48), Vector3.new(0, 5.5, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "HatBand", Vector3.new(1.56, 0.22, 1.56), Color3.fromRGB(70, 48, 30), Vector3.new(0, 5.12, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	eyes(model, Vector3.new(0, 4.35, 0.75), 0.42, 0.38, 0.18)
	newPart(model, "Mustache", Vector3.new(0.95, 0.18, 0.2), Color3.fromRGB(52, 40, 28), Vector3.new(0, 3.95, 0.78))
	for side = -1, 1, 2 do
		newPart(model, "Arm", Vector3.new(0.3, 1.6, 0.3), darkGreen, Vector3.new(0.95 * side, 2.5, 0.2), { rotation = CFrame.Angles(0, 0, math.rad(24 * side)) })
		newPart(model, "Boot", Vector3.new(0.6, 0.6, 1.1), Color3.fromRGB(96, 62, 36), Vector3.new(0.45 * side, 0.3, 0.25))
	end
	newPart(model, "Lasso", Vector3.new(1.4, 1.4, 0.16), Color3.fromRGB(214, 188, 128), Vector3.new(1.55, 1.5, 0.5), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "Belt", Vector3.new(1.82, 0.28, 1.82), Color3.fromRGB(78, 54, 34), Vector3.new(0, 1.15, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
end

function builders.flamingoAccountant(model: Model)
	local pink = Color3.fromRGB(255, 132, 176)
	local deepPink = Color3.fromRGB(232, 92, 142)
	newPart(model, "Body", Vector3.new(2.3, 2.1, 1.9), pink, Vector3.new(0, 2.4, 0), { shape = "Ball" })
	newPart(model, "Tail", Vector3.new(0.9, 1.0, 0.9), deepPink, Vector3.new(0, 2.6, -1.2), { shape = "Ball" })
	newPart(model, "Neck", Vector3.new(0.5, 2.6, 0.5), pink, Vector3.new(0, 4.3, 0.15))
	newPart(model, "Head", Vector3.new(1.1, 1.0, 1.0), pink, Vector3.new(0, 5.6, 0.1), { shape = "Ball" })
	newPart(model, "Beak", Vector3.new(0.55, 0.4, 1.0), Color3.fromRGB(36, 34, 40), Vector3.new(0, 5.5, 0.95), { rotation = CFrame.Angles(0.2, 0, 0) })
	newPart(model, "BeakTip", Vector3.new(0.4, 0.3, 0.5), Color3.fromRGB(250, 196, 88), Vector3.new(0, 5.48, 1.35))
	eyes(model, Vector3.new(0, 5.8, 0.45), 0.32, 0.3, 0.14)
	newPart(model, "Glasses", Vector3.new(1.0, 0.12, 0.12), Color3.fromRGB(40, 40, 46), Vector3.new(0, 5.8, 0.68))
	newPart(model, "Tie", Vector3.new(0.4, 1.4, 0.16), Color3.fromRGB(56, 72, 140), Vector3.new(0, 2.7, 0.92))
	newPart(model, "Collar", Vector3.new(1.0, 0.24, 0.7), Color3.fromRGB(250, 250, 255), Vector3.new(0, 3.35, 0.5))
	for side = -1, 1, 2 do
		newPart(model, "Leg", Vector3.new(0.18, 1.9, 0.18), Color3.fromRGB(240, 120, 150), Vector3.new(0.5 * side, 0.95, 0))
		newPart(model, "Foot", Vector3.new(0.5, 0.18, 0.9), deepPink, Vector3.new(0.5 * side, 0.12, 0.3))
		newPart(model, "Wing", Vector3.new(0.2, 1.4, 1.2), deepPink, Vector3.new(1.15 * side, 2.7, 0.1), { rotation = CFrame.Angles(0, 0, math.rad(12 * side)) })
	end
	newPart(model, "Briefcase", Vector3.new(1.2, 0.9, 0.4), Color3.fromRGB(104, 70, 44), Vector3.new(1.55, 1.6, 0.4))
	newPart(model, "CaseHandle", Vector3.new(0.5, 0.1, 0.1), Color3.fromRGB(58, 40, 26), Vector3.new(1.55, 2.1, 0.4))
end

function builders.croissantCactus(model: Model)
	local cactus = Color3.fromRGB(74, 152, 96)
	local pastry = Color3.fromRGB(226, 184, 104)
	newPart(model, "Trunk", Vector3.new(1.5, 3.0, 1.5), cactus, Vector3.new(0, 1.7, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "ArmLeft", Vector3.new(1.4, 1.0, 1.0), cactus, Vector3.new(-1.2, 2.2, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "ArmLeftUp", Vector3.new(0.9, 1.4, 0.9), cactus, Vector3.new(-1.6, 2.9, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "ArmRight", Vector3.new(1.2, 0.9, 0.9), cactus, Vector3.new(1.1, 1.6, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "Face", Vector3.new(1.0, 0.8, 0.3), Color3.fromRGB(96, 178, 116), Vector3.new(0, 2.2, 0.72))
	eyes(model, Vector3.new(0, 2.35, 0.9), 0.32, 0.3, 0.14)
	newPart(model, "Smile", Vector3.new(0.6, 0.12, 0.12), Color3.fromRGB(40, 80, 56), Vector3.new(0, 2.0, 0.9))
	for i = 0, 6 do
		local angle = i / 7 * math.pi * 2
		newPart(model, "Spike", Vector3.new(0.12, 0.4, 0.12), Color3.fromRGB(226, 232, 160), Vector3.new(math.cos(angle) * 0.8, 3.0, math.sin(angle) * 0.8), { rotation = CFrame.Angles(math.sin(angle) * 0.7, 0, -math.cos(angle) * 0.7) })
	end
	for i = 0, 5 do
		local angle = i / 6 * math.pi * 2
		local segment = newPart(model, "Croissant", Vector3.new(0.7, 0.7, 0.7), pastry, Vector3.new(math.cos(angle) * 0.9, 3.5, math.sin(angle) * 0.9), { shape = "Ball", material = Enum.Material.Sand })
		segment.Size = Vector3.new(0.8, 0.55, 0.8)
	end
	newPart(model, "CroissantCore", Vector3.new(1.6, 0.7, 1.6), pastry, Vector3.new(0, 3.5, 0), { shape = "Ball", material = Enum.Material.Sand })
	newPart(model, "Flower", Vector3.new(0.55, 0.35, 0.55), Color3.fromRGB(255, 120, 160), Vector3.new(0, 4.0, 0), { shape = "Ball" })
	newPart(model, "Pot", Vector3.new(2.0, 0.9, 2.0), Color3.fromRGB(180, 96, 68), Vector3.new(0, 0.45, 0))
	newPart(model, "PotRim", Vector3.new(2.2, 0.24, 2.2), Color3.fromRGB(206, 120, 86), Vector3.new(0, 0.95, 0))
end

function builders.raccoonLawyer(model: Model)
	local fur = Color3.fromRGB(124, 130, 142)
	local dark = Color3.fromRGB(58, 60, 70)
	newPart(model, "Body", Vector3.new(2.4, 2.4, 1.9), fur, Vector3.new(0, 2.2, 0))
	newPart(model, "Belly", Vector3.new(1.7, 1.8, 0.4), Color3.fromRGB(206, 210, 218), Vector3.new(0, 2.1, 0.9))
	newPart(model, "Suit", Vector3.new(2.5, 1.4, 2.0), Color3.fromRGB(38, 44, 64), Vector3.new(0, 1.5, 0))
	newPart(model, "Shirt", Vector3.new(0.8, 1.0, 0.2), Color3.fromRGB(245, 245, 250), Vector3.new(0, 2.4, 0.95))
	newPart(model, "Tie", Vector3.new(0.34, 1.1, 0.14), Color3.fromRGB(190, 50, 64), Vector3.new(0, 2.4, 1.03))
	newPart(model, "Head", Vector3.new(2.1, 1.8, 1.9), fur, Vector3.new(0, 4.0, 0))
	newPart(model, "Mask", Vector3.new(2.2, 0.75, 0.4), dark, Vector3.new(0, 4.15, 0.9))
	newPart(model, "MaskStripe", Vector3.new(0.4, 0.75, 0.2), Color3.fromRGB(226, 228, 232), Vector3.new(0, 4.15, 1.1))
	eyes(model, Vector3.new(0, 4.2, 1.1), 0.52, 0.36, 0.16)
	newPart(model, "Snout", Vector3.new(0.8, 0.5, 0.7), Color3.fromRGB(226, 228, 232), Vector3.new(0, 3.6, 1.15))
	newPart(model, "Nose", Vector3.new(0.3, 0.24, 0.24), Color3.fromRGB(26, 26, 30), Vector3.new(0, 3.66, 1.5))
	for side = -1, 1, 2 do
		newPart(model, "Ear", Vector3.new(0.7, 0.7, 0.24), dark, Vector3.new(0.75 * side, 5.0, 0), { shape = "Ball" })
		newPart(model, "Arm", Vector3.new(0.45, 1.6, 0.45), dark, Vector3.new(1.4 * side, 2.2, 0.25))
		newPart(model, "Foot", Vector3.new(0.6, 0.4, 1.0), dark, Vector3.new(0.65 * side, 0.25, 0.35))
	end
	for i = 1, 3 do
		newPart(model, "TailStripe", Vector3.new(0.55, 0.55, 0.55), if i % 2 == 0 then dark else fur, Vector3.new(0, 2.4, -1.2 - i * 0.42), { shape = "Ball" })
	end
	newPart(model, "Briefcase", Vector3.new(1.3, 0.95, 0.4), Color3.fromRGB(112, 74, 44), Vector3.new(1.6, 1.3, 0.5))
	newPart(model, "CaseHandle", Vector3.new(0.55, 0.1, 0.1), Color3.fromRGB(70, 46, 28), Vector3.new(1.6, 1.82, 0.5))
end

function builders.toiletWizard(model: Model)
	local white = Color3.fromRGB(242, 246, 250)
	local robe = Color3.fromRGB(96, 92, 214)
	newPart(model, "Bowl", Vector3.new(2.2, 1.5, 2.0), white, Vector3.new(0, 1.0, 0.1))
	newPart(model, "BowlLid", Vector3.new(2.0, 0.35, 1.8), Color3.fromRGB(220, 228, 236), Vector3.new(0, 1.85, 0.1))
	newPart(model, "Tank", Vector3.new(2.2, 2.0, 0.9), white, Vector3.new(0, 1.9, -1.1))
	newPart(model, "Seat", Vector3.new(2.5, 0.3, 2.3), Color3.fromRGB(234, 240, 246), Vector3.new(0, 1.5, 0.1))
	newPart(model, "Robe", Vector3.new(3.0, 2.4, 2.6), robe, Vector3.new(0, 3.0, -0.1), { transparency = 0.12 })
	newPart(model, "RobeTrim", Vector3.new(3.1, 0.3, 2.7), Color3.fromRGB(246, 210, 96), Vector3.new(0, 1.95, -0.1))
	newPart(model, "Head", Vector3.new(1.9, 1.7, 1.8), Color3.fromRGB(232, 196, 168), Vector3.new(0, 4.8, 0.1))
	newPart(model, "Beard", Vector3.new(1.4, 1.1, 0.6), Color3.fromRGB(238, 238, 244), Vector3.new(0, 4.0, 0.8))
	newPart(model, "HatBrim", Vector3.new(2.6, 0.18, 2.6), robe, Vector3.new(0, 5.6, 0.1), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "HatMid", Vector3.new(1.8, 1.0, 1.8), robe, Vector3.new(0, 6.05, 0.1), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "HatTip", Vector3.new(1.0, 0.8, 1.0), robe, Vector3.new(0, 6.75, 0.1), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "HatStar", Vector3.new(0.55, 0.55, 0.2), Color3.fromRGB(250, 214, 90), Vector3.new(0, 6.05, 1.05))
	eyes(model, Vector3.new(0, 4.95, 0.96), 0.4, 0.32, 0.15)
	newPart(model, "Wand", Vector3.new(0.12, 2.6, 0.12), Color3.fromRGB(120, 78, 44), Vector3.new(1.8, 4.0, 0.4), { rotation = CFrame.Angles(0, 0, math.rad(-16)) })
	newPart(model, "WandTip", Vector3.new(0.42, 0.42, 0.42), Color3.fromRGB(120, 226, 255), Vector3.new(2.18, 5.25, 0.4), { shape = "Ball", material = Enum.Material.Neon })
	newPart(model, "FlushHandle", Vector3.new(0.24, 0.5, 0.24), Color3.fromRGB(190, 198, 208), Vector3.new(1.15, 2.2, -1.1))
end

function builders.pigeonOverlord(model: Model)
	local gray = Color3.fromRGB(146, 156, 174)
	local dark = Color3.fromRGB(88, 96, 112)
	local gold = Color3.fromRGB(250, 204, 68)
	newPart(model, "Body", Vector3.new(2.6, 2.2, 2.0), gray, Vector3.new(0, 2.1, 0), { shape = "Ball" })
	newPart(model, "Chest", Vector3.new(1.8, 1.5, 0.5), Color3.fromRGB(186, 196, 212), Vector3.new(0, 2.0, 0.95))
	newPart(model, "Head", Vector3.new(1.5, 1.4, 1.4), gray, Vector3.new(0, 3.8, 0.2), { shape = "Ball" })
	newPart(model, "Beak", Vector3.new(0.4, 0.35, 0.8), Color3.fromRGB(246, 168, 76), Vector3.new(0, 3.72, 1.0))
	newPart(model, "Wattle", Vector3.new(0.35, 0.4, 0.3), Color3.fromRGB(232, 96, 110), Vector3.new(0, 3.45, 1.0))
	eyes(model, Vector3.new(0, 3.95, 0.92), 0.34, 0.3, 0.13)
	newPart(model, "CrownBase", Vector3.new(1.4, 0.24, 1.4), gold, Vector3.new(0, 4.6, 0.2), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)), material = Enum.Material.Neon })
	for i = 0, 4 do
		local angle = i / 5 * math.pi * 2
		newPart(model, "CrownSpike", Vector3.new(0.2, 0.6, 0.2), gold, Vector3.new(math.cos(angle) * 0.55, 4.95, 0.2 + math.sin(angle) * 0.55), { material = Enum.Material.Neon })
	end
	for side = -1, 1, 2 do
		newPart(model, "Wing", Vector3.new(0.3, 1.6, 1.8), dark, Vector3.new(1.3 * side, 2.2, -0.1), { rotation = CFrame.Angles(0, 0, math.rad(10 * side)) })
		newPart(model, "Leg", Vector3.new(0.18, 0.9, 0.18), Color3.fromRGB(238, 152, 88), Vector3.new(0.45 * side, 0.75, 0.1))
		newPart(model, "Foot", Vector3.new(0.55, 0.15, 0.7), Color3.fromRGB(238, 152, 88), Vector3.new(0.45 * side, 0.3, 0.4))
	end
	newPart(model, "Tail", Vector3.new(1.4, 0.3, 1.0), dark, Vector3.new(0, 1.5, -1.1), { rotation = CFrame.Angles(0.3, 0, 0) })
	newPart(model, "Cape", Vector3.new(2.0, 2.6, 0.2), Color3.fromRGB(180, 56, 76), Vector3.new(0, 2.4, -1.1), { rotation = CFrame.Angles(-0.12, 0, 0) })
end

function builders.mangoMafiaDon(model: Model)
	local mango = Color3.fromRGB(255, 146, 48)
	local suit = Color3.fromRGB(48, 44, 64)
	newPart(model, "Body", Vector3.new(2.6, 2.6, 2.2), mango, Vector3.new(0, 2.3, 0), { shape = "Ball" })
	newPart(model, "Suit", Vector3.new(2.7, 1.5, 2.3), suit, Vector3.new(0, 1.5, 0))
	newPart(model, "Shirt", Vector3.new(1.0, 1.1, 0.2), Color3.fromRGB(248, 246, 240), Vector3.new(0, 2.4, 1.08))
	newPart(model, "Tie", Vector3.new(0.4, 1.2, 0.16), Color3.fromRGB(220, 190, 70), Vector3.new(0, 2.35, 1.16))
	newPart(model, "Chain", Vector3.new(1.6, 0.18, 0.2), Color3.fromRGB(252, 208, 74), Vector3.new(0, 2.9, 1.05), { material = Enum.Material.Neon })
	newPart(model, "Pendant", Vector3.new(0.4, 0.4, 0.2), Color3.fromRGB(252, 208, 74), Vector3.new(0, 2.6, 1.15), { shape = "Ball", material = Enum.Material.Neon })
	newPart(model, "Head", Vector3.new(2.2, 2.0, 2.0), mango, Vector3.new(0, 4.3, 0), { shape = "Ball" })
	newPart(model, "FedoraBrim", Vector3.new(2.9, 0.18, 2.9), Color3.fromRGB(30, 30, 38), Vector3.new(0, 5.2, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "FedoraTop", Vector3.new(1.8, 1.1, 1.8), Color3.fromRGB(38, 38, 46), Vector3.new(0, 5.75, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "FedoraBand", Vector3.new(1.86, 0.24, 1.86), Color3.fromRGB(196, 158, 64), Vector3.new(0, 5.32, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(90)) })
	newPart(model, "Shades", Vector3.new(1.7, 0.42, 0.2), Color3.fromRGB(20, 20, 26), Vector3.new(0, 4.45, 0.95))
	newPart(model, "ShadesBridge", Vector3.new(0.4, 0.14, 0.14), Color3.fromRGB(20, 20, 26), Vector3.new(0, 4.58, 1.0))
	newPart(model, "Cigar", Vector3.new(0.22, 0.9, 0.22), Color3.fromRGB(122, 80, 44), Vector3.new(0.7, 3.9, 1.15), { rotation = CFrame.Angles(0, 0, math.rad(78)) })
	newPart(model, "CigarTip", Vector3.new(0.24, 0.18, 0.24), Color3.fromRGB(255, 120, 60), Vector3.new(1.05, 3.96, 1.15), { material = Enum.Material.Neon })
	for side = -1, 1, 2 do
		newPart(model, "Arm", Vector3.new(0.5, 1.7, 0.5), suit, Vector3.new(1.5 * side, 2.2, 0.1), { rotation = CFrame.Angles(0, 0, math.rad(12 * side)) })
		newPart(model, "Shoe", Vector3.new(0.9, 0.4, 1.4), Color3.fromRGB(24, 24, 30), Vector3.new(0.7 * side, 0.2, 0.3))
	end
	newPart(model, "Leaf", Vector3.new(0.8, 0.2, 0.5), Color3.fromRGB(90, 168, 80), Vector3.new(0.2, 5.95, -0.4), { rotation = CFrame.Angles(0.2, 0.4, 0) })
end

function builders.bananaBureaucrat(model: Model)
	local yellow = Color3.fromRGB(245, 214, 84)
	local brown = Color3.fromRGB(146, 106, 52)
	newPart(model, "BananaBottom", Vector3.new(1.5, 1.6, 1.5), yellow, Vector3.new(0, 1.3, 0), { shape = "Ball" })
	newPart(model, "BananaMid", Vector3.new(1.6, 1.9, 1.6), yellow, Vector3.new(-0.55, 2.5, 0), { shape = "Cylinder", rotation = CFrame.Angles(0, 0, math.rad(66)) })
	newPart(model, "BananaTop", Vector3.new(1.4, 1.5, 1.4), yellow, Vector3.new(-1.35, 3.5, 0), { shape = "Ball" })
	newPart(model, "BananaTip", Vector3.new(0.55, 0.55, 0.55), brown, Vector3.new(-2.0, 3.95, 0), { shape = "Ball" })
	newPart(model, "Head", Vector3.new(1.7, 1.5, 1.5), Color3.fromRGB(250, 226, 118), Vector3.new(-0.2, 4.1, 0), { shape = "Ball" })
	newPart(model, "Glasses", Vector3.new(1.3, 0.18, 0.14), Color3.fromRGB(40, 40, 48), Vector3.new(-0.2, 4.25, 0.72))
	eyes(model, Vector3.new(-0.2, 4.25, 0.62), 0.36, 0.28, 0.13)
	newPart(model, "Mustache", Vector3.new(0.8, 0.16, 0.16), brown, Vector3.new(-0.2, 3.9, 0.75))
	newPart(model, "Suit", Vector3.new(1.5, 1.3, 1.4), Color3.fromRGB(66, 72, 110), Vector3.new(0.1, 1.6, 0))
	newPart(model, "Tie", Vector3.new(0.3, 1.0, 0.14), Color3.fromRGB(180, 60, 70), Vector3.new(0.3, 2.0, 0.72))
	newPart(model, "Badge", Vector3.new(0.3, 0.3, 0.1), Color3.fromRGB(240, 200, 70), Vector3.new(0.6, 2.3, 0.7), { shape = "Ball" })
	newPart(model, "Clipboard", Vector3.new(0.9, 1.3, 0.12), Color3.fromRGB(196, 156, 100), Vector3.new(1.4, 2.6, 0.4), { rotation = CFrame.Angles(0, -0.4, 0.12) })
	newPart(model, "Paper", Vector3.new(0.7, 1.1, 0.06), Color3.fromRGB(248, 248, 244), Vector3.new(1.4, 2.62, 0.47), { rotation = CFrame.Angles(0, -0.4, 0.12) })
	newPart(model, "Stamp", Vector3.new(0.3, 0.5, 0.3), Color3.fromRGB(200, 40, 50), Vector3.new(0.9, 3.0, 0.6))
	newPart(model, "StampBase", Vector3.new(0.5, 0.14, 0.5), Color3.fromRGB(60, 60, 66), Vector3.new(0.9, 2.72, 0.6))
	for side = -1, 1, 2 do
		newPart(model, "Shoe", Vector3.new(0.7, 0.4, 1.1), Color3.fromRGB(50, 44, 40), Vector3.new(0.2 + 0.5 * side, 0.2, 0.35))
	end
end

-- The catalog indexes these builders by the `builder` field of each definition.
BrainrotModel.Builders = builders

function BrainrotModel.build(def): Model
	local model = Instance.new("Model")
	model.Name = def.id
	newRoot(model)
	local buildOne = builders[def.builder] or builders.capybaraChef
	buildOne(model)
	return model
end

function BrainrotModel.labelOffsetY(model: Model): number
	local pivot = model:GetPivot()
	local inverse = pivot:Inverse()
	local highest = 2
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "Root" then
			local localCenter = inverse * descendant.CFrame.Position
			local top = localCenter.Y + descendant.Size.Y / 2
			highest = math.max(highest, top)
		end
	end
	return highest + 1.4
end

function BrainrotModel.applyMutation(model: Model, mutationId: string)
	local mutation = BrainrotDefs.mutationInfo(mutationId)
	if mutation.label == "" then
		return
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "Root" then
			if descendant.Material == Enum.Material.Neon then
				descendant.Color = mutation.color
			else
				descendant.Color = descendant.Color:Lerp(mutation.color, 0.5)
				descendant.Reflectance = 0.2
			end
		end
	end
	local root = model.PrimaryPart
	if root then
		local light = Instance.new("PointLight")
		light.Color = mutation.color
		light.Brightness = 1.6
		light.Range = 14
		light.Parent = root
	end
end

function BrainrotModel.addLabel(model: Model, def, mutationId: string): BillboardGui
	local mutation = BrainrotDefs.mutationInfo(mutationId)
	local rarityColor = BrainrotDefs.rarityColor(def.rarity)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(230, 68)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, BrainrotModel.labelOffsetY(model), 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 160
	billboard.LightInfluence = 0
	billboard.Adornee = model.PrimaryPart
	billboard.Parent = model.PrimaryPart

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
	card.BackgroundTransparency = 0.18
	card.BorderSizePixel = 0
	card.Parent = billboard
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = rarityColor
	cardStroke.Thickness = 2
	cardStroke.Transparency = 0.1
	cardStroke.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Position = UDim2.new(0, 8, 0, 4)
	nameLabel.Size = UDim2.new(1, -16, 0, 26)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = BrainrotDefs.displayName(def, mutationId)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 17
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Position = UDim2.new(0, 8, 0, 30)
	rarityLabel.Size = UDim2.new(0.55, 0, 0, 18)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = string.upper(def.rarity)
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.TextSize = 13
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
	rarityLabel.Parent = card

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.Position = UDim2.new(0.5, 0, 0, 28)
	rateLabel.Size = UDim2.new(0.5, -8, 0, 20)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = Format.rate(BrainrotDefs.rateFor(def, mutationId))
	rateLabel.TextColor3 = Color3.fromRGB(120, 240, 156)
	rateLabel.TextSize = 15
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.TextXAlignment = Enum.TextXAlignment.Right
	rateLabel.Parent = card

	if mutation.label ~= "" then
		local mutationLabel = Instance.new("TextLabel")
		mutationLabel.Name = "Mutation"
		mutationLabel.Position = UDim2.new(0, 8, 0, 50)
		mutationLabel.Size = UDim2.new(1, -16, 0, 14)
		mutationLabel.BackgroundTransparency = 1
		mutationLabel.Text = mutation.label .. " MUTATION"
		mutationLabel.TextColor3 = mutation.color
		mutationLabel.TextSize = 11
		mutationLabel.Font = Enum.Font.GothamBold
		mutationLabel.TextXAlignment = Enum.TextXAlignment.Left
		mutationLabel.Parent = card
	end

	return billboard
end

return BrainrotModel
