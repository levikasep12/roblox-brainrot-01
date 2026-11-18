-- The brainrot cast: eleven original characters, each with a rarity, a
-- money-per-second rate, a shop price and a procedural build spec (parts,
-- colours, face and accessories). BrainrotModel turns a spec into a Model.

local BrainrotDefs = {}

BrainrotDefs.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

BrainrotDefs.RarityColor = {
	Common = Color3.fromRGB(214, 220, 226),
	Rare = Color3.fromRGB(86, 158, 255),
	Epic = Color3.fromRGB(186, 104, 255),
	Legendary = Color3.fromRGB(255, 176, 46),
	Mythic = Color3.fromRGB(255, 74, 138),
}

BrainrotDefs.RarityGlow = {
	Common = 0,
	Rare = 0.6,
	Epic = 1.2,
	Legendary = 2.4,
	Mythic = 4.0,
}

BrainrotDefs.Mutations = {
	Golden = { rateMultiplier = 2.5, tint = Color3.fromRGB(255, 205, 64), sparkle = Color3.fromRGB(255, 236, 140) },
	Diamond = { rateMultiplier = 5, tint = Color3.fromRGB(132, 232, 255), sparkle = Color3.fromRGB(210, 250, 255) },
}

local function build(def)
	if not def.price then
		def.price = math.floor(def.rate * 40 + 0.5)
	end
	return def
end

BrainrotDefs.Cast = {
	build({
		id = "bananaconda",
		name = "Bananaconda",
		rarity = "Common",
		rate = 4,
		price = 100,
		blurb = "A banana that swallowed a snake, or the reverse. Nobody dares ask.",
		body = { shape = "Cylinder", size = Vector3.new(2.2, 6.4, 2.2), color = Color3.fromRGB(255, 214, 72) },
		rotateBody = Vector3.new(0, 0, 90),
		head = { shape = "Ball", size = Vector3.new(2.9, 2.9, 2.9), offset = Vector3.new(2.6, 1.7, 0), color = Color3.fromRGB(255, 230, 120) },
		face = { offset = Vector3.new(2.6, 1.7, 0), size = Vector3.new(2.6, 2.4, 2.3) },
		-- This head hangs off the banana's +X end, so its face looks along +X.
		faceForward = Vector3.new(1, 0, 0),
		parts = {
			{ shape = "Cylinder", size = Vector3.new(0.5, 0.9, 0.5), offset = Vector3.new(2.2, 1.7, 0), rotation = Vector3.new(90, 0, 0), color = Color3.fromRGB(70, 45, 20), name = "Stem" },
			{ shape = "Ball", size = Vector3.new(0.45, 0.9, 0.45), offset = Vector3.new(-2.9, -1.4, 0), color = Color3.fromRGB(255, 230, 120), name = "TailTip" },
			{ shape = "Ball", size = Vector3.new(1.1, 0.7, 1.1), offset = Vector3.new(-0.6, -1.1, 0), color = Color3.fromRGB(255, 214, 72), name = "BumpA" },
		},
	}),
	build({
		id = "skibidi_toaster",
		name = "Skibidi Toaster",
		rarity = "Common",
		rate = 7,
		price = 175,
		blurb = "It only knows one song and it will not stop performing it.",
		body = { shape = "Block", size = Vector3.new(4.4, 3.4, 3.4), color = Color3.fromRGB(232, 236, 242) },
		head = { shape = "Block", size = Vector3.new(2.4, 2.4, 2.2), offset = Vector3.new(0, 2.9, 0), color = Color3.fromRGB(255, 224, 190) },
		face = { offset = Vector3.new(0, 2.9, 1.1), size = Vector3.new(2.1, 2.0, 0.4) },
		parts = {
			{ shape = "Block", size = Vector3.new(3.0, 0.5, 2.6), offset = Vector3.new(0, 2.0, 0), color = Color3.fromRGB(150, 158, 168), name = "Slot" },
			{ shape = "Block", size = Vector3.new(0.9, 1.5, 0.9), offset = Vector3.new(0, 3.4, -1.5), color = Color3.fromRGB(255, 150, 40), name = "Bread" },
			{ shape = "Block", size = Vector3.new(4.6, 0.35, 3.5), offset = Vector3.new(0, -1.85, 0), color = Color3.fromRGB(120, 128, 140), name = "Tray" },
			{ shape = "Ball", size = Vector3.new(0.5, 0.5, 0.5), offset = Vector3.new(-1.6, 0.4, 1.8), color = Color3.fromRGB(255, 90, 90), name = "Dial" },
			{ shape = "Cylinder", size = Vector3.new(0.35, 0.8, 0.35), offset = Vector3.new(1.7, -0.4, 1.8), rotation = Vector3.new(0, 0, 90), color = Color3.fromRGB(80, 200, 130), name = "Knob" },
		},
	}),
	build({
		id = "capybara_chef",
		name = "Capybara Chef",
		rarity = "Rare",
		rate = 14,
		price = 420,
		blurb = "Calmest chef alive. Serves soup at exactly body temperature.",
		body = { shape = "Block", size = Vector3.new(4.6, 3.6, 5.0), color = Color3.fromRGB(150, 104, 62) },
		head = { shape = "Block", size = Vector3.new(3.6, 3.0, 3.6), offset = Vector3.new(0, 3.2, 1.4), color = Color3.fromRGB(160, 112, 68) },
		face = { offset = Vector3.new(0, 3.1, 3.2), size = Vector3.new(3.2, 2.6, 0.4) },
		parts = {
			{ shape = "Block", size = Vector3.new(2.6, 0.25, 0.4), offset = Vector3.new(0, 2.2, 3.3), color = Color3.fromRGB(120, 78, 46), name = "Muzzle" },
			{ shape = "Cylinder", size = Vector3.new(3.4, 1.9, 3.4), offset = Vector3.new(0, 5.2, 1.4), color = Color3.fromRGB(250, 250, 250), name = "ChefHat" },
			{ shape = "Ball", size = Vector3.new(3.6, 1.6, 3.6), offset = Vector3.new(0, 6.0, 1.4), color = Color3.fromRGB(255, 255, 255), name = "ChefPuff" },
			{ shape = "Cylinder", size = Vector3.new(1.9, 1.5, 1.9), offset = Vector3.new(-3.2, -0.4, 1.6), rotation = Vector3.new(0, 0, 90), color = Color3.fromRGB(150, 104, 62), name = "ArmL" },
			{ shape = "Block", size = Vector3.new(1.6, 1.5, 1.6), offset = Vector3.new(-4.4, -0.4, 1.6), color = Color3.fromRGB(200, 210, 220), name = "Pot" },
			{ shape = "Cylinder", size = Vector3.new(1.0, 0.4, 1.0), offset = Vector3.new(-4.4, 0.5, 1.6), color = Color3.fromRGB(255, 200, 90), name = "Soup" },
		},
	}),
	build({
		id = "durian_dj",
		name = "Durian DJ",
		rarity = "Rare",
		rate = 22,
		price = 660,
		blurb = "Banned from three kitchens and two nightclubs for the same reason.",
		body = { shape = "Ball", size = Vector3.new(5.2, 5.2, 5.2), color = Color3.fromRGB(172, 196, 84) },
		head = { shape = "Ball", size = Vector3.new(2.4, 2.0, 2.2), offset = Vector3.new(0, -0.2, 2.5), color = Color3.fromRGB(196, 214, 110) },
		face = { offset = Vector3.new(0, -0.2, 3.5), size = Vector3.new(2.2, 1.8, 0.4) },
		parts = {
			{ shape = "Cylinder", size = Vector3.new(0.9, 1.4, 0.9), offset = Vector3.new(0, 2.9, 0), color = Color3.fromRGB(110, 130, 60), name = "Stalk" },
			{ shape = "Cylinder", size = Vector3.new(0.6, 4.6, 0.6), offset = Vector3.new(2.6, 0, 0), rotation = Vector3.new(0, 0, 90), color = Color3.fromRGB(60, 66, 78), name = "Headband" },
			{ shape = "Cylinder", size = Vector3.new(2.4, 1.0, 2.4), offset = Vector3.new(-2.8, 0.4, 0), rotation = Vector3.new(0, 0, 90), color = Color3.fromRGB(40, 44, 54), name = "CupL" },
			{ shape = "Cylinder", size = Vector3.new(2.4, 1.0, 2.4), offset = Vector3.new(2.8, 0.4, 0), rotation = Vector3.new(0, 0, 90), color = Color3.fromRGB(40, 44, 54), name = "CupR" },
			{ shape = "Block", size = Vector3.new(1.2, 0.9, 0.5), offset = Vector3.new(0, -2.0, 2.5), color = Color3.fromRGB(240, 240, 250), name = "Grill" },
			{ shape = "Block", size = Vector3.new(3.6, 1.0, 2.6), offset = Vector3.new(0, -2.6, 2.0), color = Color3.fromRGB(70, 76, 92), name = "Deck" },
		},
	}),
	build({
		id = "waffle_wizard",
		name = "Waffle Wizard",
		rarity = "Epic",
		rate = 45,
		price = 1575,
		blurb = "Casts spells that are legally indistinguishable from breakfast.",
		body = { shape = "Cylinder", size = Vector3.new(4.2, 4.4, 4.2), color = Color3.fromRGB(226, 170, 84) },
		head = { shape = "Cylinder", size = Vector3.new(3.4, 1.2, 3.4), offset = Vector3.new(0, 2.4, 0), color = Color3.fromRGB(240, 196, 112) },
		face = { offset = Vector3.new(0, 2.2, 1.9), size = Vector3.new(2.6, 2.0, 0.4) },
		parts = {
			{ shape = "Block", size = Vector3.new(3.0, 0.3, 4.0), offset = Vector3.new(0, 1.7, 0.4), color = Color3.fromRGB(255, 248, 210), name = "Butter" },
			{ shape = "Block", size = Vector3.new(3.2, 0.2, 3.2), offset = Vector3.new(0, 2.95, 0), color = Color3.fromRGB(160, 96, 40), name = "Syrup" },
			{ shape = "Cylinder", size = Vector3.new(2.6, 2.4, 2.6), offset = Vector3.new(0, 4.4, -0.4), color = Color3.fromRGB(86, 74, 200), name = "HatBrim" },
			{ shape = "Wedge", size = Vector3.new(2.6, 3.6, 2.6), offset = Vector3.new(0, 6.4, -0.4), color = Color3.fromRGB(96, 84, 220), name = "HatCone" },
			{ shape = "Ball", size = Vector3.new(0.8, 0.8, 0.8), offset = Vector3.new(0, 8.4, -0.4), color = Color3.fromRGB(255, 220, 90), name = "HatStar" },
			{ shape = "Cylinder", size = Vector3.new(0.4, 6.4, 0.4), offset = Vector3.new(3.4, -0.2, 1.0), color = Color3.fromRGB(120, 74, 40), name = "Staff" },
			{ shape = "Ball", size = Vector3.new(1.2, 1.2, 1.2), offset = Vector3.new(3.4, 3.2, 1.0), color = Color3.fromRGB(120, 255, 220), name = "Orb" },
		},
	}),
	build({
		id = "bombardiro_cactus",
		name = "Bombardiro Cactus",
		rarity = "Epic",
		rate = 70,
		price = 2450,
		blurb = "A cactus with opinions about air travel and the means to share them.",
		body = { shape = "Cylinder", size = Vector3.new(3.4, 5.6, 3.4), color = Color3.fromRGB(74, 156, 96) },
		head = { shape = "Ball", size = Vector3.new(3.0, 3.0, 3.0), offset = Vector3.new(0, 3.4, 0), color = Color3.fromRGB(88, 172, 110) },
		face = { offset = Vector3.new(0, 3.4, 1.5), size = Vector3.new(2.4, 2.0, 0.4) },
		parts = {
			{ shape = "Cylinder", size = Vector3.new(1.2, 2.4, 1.2), offset = Vector3.new(-2.4, 0.8, 0), rotation = Vector3.new(0, 0, 90), color = Color3.fromRGB(74, 156, 96), name = "ArmL" },
			{ shape = "Cylinder", size = Vector3.new(1.2, 2.4, 1.2), offset = Vector3.new(2.4, 0.8, 0), rotation = Vector3.new(0, 0, 90), color = Color3.fromRGB(74, 156, 96), name = "ArmR" },
			{ shape = "Block", size = Vector3.new(6.4, 0.5, 1.6), offset = Vector3.new(0, 1.4, 0), color = Color3.fromRGB(118, 120, 128), name = "Wing" },
			{ shape = "Ball", size = Vector3.new(0.35, 0.8, 0.35), offset = Vector3.new(-1.9, 2.0, 0), color = Color3.fromRGB(250, 240, 190), name = "SpikeA" },
			{ shape = "Ball", size = Vector3.new(0.35, 0.8, 0.35), offset = Vector3.new(1.9, 2.0, 0), color = Color3.fromRGB(250, 240, 190), name = "SpikeB" },
			{ shape = "Ball", size = Vector3.new(2.2, 1.0, 1.0), offset = Vector3.new(0, -2.8, 1.2), color = Color3.fromRGB(60, 62, 72), name = "BombBay" },
			{ shape = "Ball", size = Vector3.new(1.0, 1.0, 1.0), offset = Vector3.new(0, -4.2, 1.2), color = Color3.fromRGB(40, 42, 50), name = "Bomb" },
		},
	}),
	build({
		id = "flamingo_accountant",
		name = "Flamingo Accountant",
		rarity = "Epic",
		rate = 95,
		price = 3325,
		blurb = "Balances your books, then balances on one leg for six hours.",
		body = { shape = "Ball", size = Vector3.new(3.6, 3.6, 3.4), color = Color3.fromRGB(255, 138, 176) },
		head = { shape = "Ball", size = Vector3.new(2.0, 2.4, 2.0), offset = Vector3.new(0, 3.6, 0.6), color = Color3.fromRGB(255, 156, 190) },
		face = { offset = Vector3.new(0, 3.6, 1.5), size = Vector3.new(1.8, 1.6, 0.4) },
		parts = {
			{ shape = "Cylinder", size = Vector3.new(0.7, 2.2, 0.7), offset = Vector3.new(0, 2.0, 0.4), color = Color3.fromRGB(255, 156, 190), name = "Neck" },
			{ shape = "Block", size = Vector3.new(0.8, 0.8, 1.8), offset = Vector3.new(0, 3.4, 2.4), color = Color3.fromRGB(250, 168, 64), name = "Beak" },
			{ shape = "Cylinder", size = Vector3.new(0.35, 4.4, 0.35), offset = Vector3.new(0.4, -3.0, 0), color = Color3.fromRGB(255, 152, 96), name = "LegL" },
			{ shape = "Cylinder", size = Vector3.new(0.35, 4.4, 0.35), offset = Vector3.new(-0.5, -3.0, 0.3), color = Color3.fromRGB(255, 152, 96), name = "LegR" },
			{ shape = "Wedge", size = Vector3.new(1.4, 2.2, 1.2), offset = Vector3.new(0, -0.9, -1.6), color = Color3.fromRGB(52, 64, 96), name = "SuitJacket" },
			{ shape = "Block", size = Vector3.new(0.6, 2.0, 0.3), offset = Vector3.new(0, 0.2, 1.7), color = Color3.fromRGB(240, 60, 70), name = "Tie" },
			{ shape = "Block", size = Vector3.new(1.6, 1.2, 0.4), offset = Vector3.new(1.8, -0.4, 1.2), color = Color3.fromRGB(250, 250, 240), name = "Clipboard" },
		},
	}),
	build({
		id = "tralalero_taxi",
		name = "Tralalero Taxi",
		rarity = "Legendary",
		rate = 200,
		price = 8000,
		blurb = "Three legs, one sneaker each, and a meter that has never been reset.",
		body = { shape = "Block", size = Vector3.new(3.2, 4.6, 6.2), color = Color3.fromRGB(112, 158, 206) },
		head = { shape = "Wedge", size = Vector3.new(3.2, 2.6, 3.4), offset = Vector3.new(0, 2.0, 4.0), color = Color3.fromRGB(124, 172, 218) },
		face = { offset = Vector3.new(0, 1.6, 5.4), size = Vector3.new(2.6, 1.6, 0.4) },
		parts = {
			{ shape = "Block", size = Vector3.new(1.6, 0.8, 3.6), offset = Vector3.new(0, 0.6, -3.2), color = Color3.fromRGB(124, 172, 218), name = "Tail" },
			{ shape = "Wedge", size = Vector3.new(3.0, 1.8, 1.4), offset = Vector3.new(0, 3.0, -1.0), color = Color3.fromRGB(124, 172, 218), name = "Fin" },
			{ shape = "Cylinder", size = Vector3.new(1.0, 2.0, 1.0), offset = Vector3.new(-1.4, -2.6, 1.2), color = Color3.fromRGB(124, 172, 218), name = "LegL" },
			{ shape = "Cylinder", size = Vector3.new(1.0, 2.0, 1.0), offset = Vector3.new(1.4, -2.6, 1.2), color = Color3.fromRGB(124, 172, 218), name = "LegR" },
			{ shape = "Cylinder", size = Vector3.new(1.0, 2.0, 1.0), offset = Vector3.new(0, -2.6, -2.4), color = Color3.fromRGB(124, 172, 218), name = "LegB" },
			{ shape = "Block", size = Vector3.new(1.3, 0.8, 2.0), offset = Vector3.new(-1.4, -4.0, 1.6), color = Color3.fromRGB(250, 250, 250), name = "ShoeL" },
			{ shape = "Block", size = Vector3.new(1.3, 0.8, 2.0), offset = Vector3.new(1.4, -4.0, 1.6), color = Color3.fromRGB(250, 250, 250), name = "ShoeR" },
			{ shape = "Block", size = Vector3.new(1.3, 0.8, 2.0), offset = Vector3.new(0, -4.0, -2.0), color = Color3.fromRGB(250, 250, 250), name = "ShoeB" },
			{ shape = "Block", size = Vector3.new(1.8, 0.5, 0.6), offset = Vector3.new(0, 2.4, 4.4), color = Color3.fromRGB(60, 62, 70), name = "Teeth" },
			{ shape = "Block", size = Vector3.new(1.4, 0.9, 0.5), offset = Vector3.new(0, 4.6, 1.4), color = Color3.fromRGB(255, 214, 74), name = "TaxiSign" },
		},
	}),
	build({
		id = "cappuccino_kraken",
		name = "Cappuccino Kraken",
		rarity = "Legendary",
		rate = 320,
		price = 12800,
		blurb = "Eight arms, one cup, zero patience for oat milk substitutions.",
		body = { shape = "Ball", size = Vector3.new(4.6, 4.2, 4.6), color = Color3.fromRGB(196, 128, 96) },
		head = { shape = "Ball", size = Vector3.new(2.6, 2.2, 2.4), offset = Vector3.new(0, 1.4, 2.6), color = Color3.fromRGB(214, 150, 116) },
		face = { offset = Vector3.new(0, 1.4, 3.7), size = Vector3.new(2.2, 1.6, 0.4) },
		parts = {
			{ shape = "Cylinder", size = Vector3.new(3.4, 1.6, 3.4), offset = Vector3.new(0, 4.0, 0), color = Color3.fromRGB(245, 240, 232), name = "Saucer" },
			{ shape = "Cylinder", size = Vector3.new(2.6, 2.2, 2.6), offset = Vector3.new(0, 5.0, 0), color = Color3.fromRGB(118, 78, 56), name = "Cup" },
			{ shape = "Cylinder", size = Vector3.new(2.2, 0.3, 2.2), offset = Vector3.new(0, 6.05, 0), color = Color3.fromRGB(228, 214, 190), name = "Foam" },
			{ shape = "Cylinder", size = Vector3.new(0.9, 1.2, 0.9), offset = Vector3.new(1.7, 5.0, 0), rotation = Vector3.new(0, 0, 90), color = Color3.fromRGB(118, 78, 56), name = "Handle" },
			{ shape = "Cylinder", size = Vector3.new(0.8, 3.2, 0.8), offset = Vector3.new(-2.6, -1.4, 1.4), rotation = Vector3.new(0, 30, 30), color = Color3.fromRGB(196, 128, 96), name = "ArmA" },
			{ shape = "Cylinder", size = Vector3.new(0.8, 3.2, 0.8), offset = Vector3.new(2.6, -1.4, 1.4), rotation = Vector3.new(0, -30, -30), color = Color3.fromRGB(196, 128, 96), name = "ArmB" },
			{ shape = "Cylinder", size = Vector3.new(0.8, 3.2, 0.8), offset = Vector3.new(-1.8, -1.6, -2.4), rotation = Vector3.new(30, 0, 40), color = Color3.fromRGB(196, 128, 96), name = "ArmC" },
			{ shape = "Cylinder", size = Vector3.new(0.8, 3.2, 0.8), offset = Vector3.new(1.8, -1.6, -2.4), rotation = Vector3.new(-30, 0, -40), color = Color3.fromRGB(196, 128, 96), name = "ArmD" },
			{ shape = "Ball", size = Vector3.new(0.8, 0.8, 0.8), offset = Vector3.new(0, 6.4, 0), color = Color3.fromRGB(255, 250, 240), name = "Steam" },
		},
	}),
	build({
		id = "giga_nuggler",
		name = "Giga Nuggler",
		rarity = "Mythic",
		rate = 1000,
		price = 45000,
		blurb = "It is a nugget the size of a bus and it is made of smaller nuggets.",
		body = { shape = "Block", size = Vector3.new(6.4, 5.2, 5.8), color = Color3.fromRGB(226, 158, 66) },
		head = { shape = "Block", size = Vector3.new(4.4, 3.6, 4.0), offset = Vector3.new(0, 4.2, 0.4), color = Color3.fromRGB(240, 174, 82) },
		face = { offset = Vector3.new(0, 4.2, 2.5), size = Vector3.new(3.6, 2.6, 0.4) },
		parts = {
			{ shape = "Ball", size = Vector3.new(2.4, 2.4, 2.4), offset = Vector3.new(-3.6, -0.6, 0.6), color = Color3.fromRGB(198, 136, 52), name = "NuggetL" },
			{ shape = "Ball", size = Vector3.new(2.0, 2.0, 2.0), offset = Vector3.new(3.5, -1.2, -0.6), color = Color3.fromRGB(208, 144, 56), name = "NuggetR" },
			{ shape = "Ball", size = Vector3.new(1.6, 1.6, 1.6), offset = Vector3.new(2.0, 2.4, -2.6), color = Color3.fromRGB(214, 150, 60), name = "NuggetTop" },
			{ shape = "Cylinder", size = Vector3.new(1.6, 3.4, 1.6), offset = Vector3.new(-4.4, 1.6, -1.0), rotation = Vector3.new(0, 0, 40), color = Color3.fromRGB(226, 158, 66), name = "ArmL" },
			{ shape = "Cylinder", size = Vector3.new(1.6, 3.4, 1.6), offset = Vector3.new(4.4, 1.6, -1.0), rotation = Vector3.new(0, 0, -40), color = Color3.fromRGB(226, 158, 66), name = "ArmR" },
			{ shape = "Cylinder", size = Vector3.new(2.2, 2.0, 2.2), offset = Vector3.new(0, 7.2, 0.6), color = Color3.fromRGB(110, 66, 40), name = "Bucket" },
			{ shape = "Block", size = Vector3.new(1.0, 1.0, 1.0), offset = Vector3.new(0, 8.6, 0.6), color = Color3.fromRGB(255, 236, 120), name = "Crown" },
		},
	}),
	build({
		id = "lirili_larila",
		name = "Lirili Larila",
		rarity = "Mythic",
		rate = 1800,
		price = 90000,
		blurb = "Half cactus, half elephant, entirely convinced it is a bird.",
		body = { shape = "Cylinder", size = Vector3.new(5.6, 5.0, 5.0), color = Color3.fromRGB(172, 190, 96) },
		head = { shape = "Ball", size = Vector3.new(3.4, 3.2, 3.4), offset = Vector3.new(0, 1.6, 3.5), color = Color3.fromRGB(192, 206, 116) },
		face = { offset = Vector3.new(0, 1.6, 5.1), size = Vector3.new(3.0, 2.2, 0.4) },
		parts = {
			{ shape = "Cylinder", size = Vector3.new(1.4, 3.6, 1.4), offset = Vector3.new(0, 0.6, 5.6), rotation = Vector3.new(60, 0, 0), color = Color3.fromRGB(192, 206, 116), name = "Trunk" },
			{ shape = "Cylinder", size = Vector3.new(3.6, 3.2, 3.6), offset = Vector3.new(-3.4, 2.4, 0), rotation = Vector3.new(0, 0, 60), color = Color3.fromRGB(172, 190, 96), name = "EarL" },
			{ shape = "Cylinder", size = Vector3.new(3.6, 3.2, 3.6), offset = Vector3.new(3.4, 2.4, 0), rotation = Vector3.new(0, 0, -60), color = Color3.fromRGB(172, 190, 96), name = "EarR" },
			{ shape = "Ball", size = Vector3.new(1.0, 1.0, 1.0), offset = Vector3.new(2.2, 4.2, 0), color = Color3.fromRGB(255, 110, 140), name = "FlowerA" },
			{ shape = "Ball", size = Vector3.new(1.0, 1.0, 1.0), offset = Vector3.new(-2.2, 4.0, 0.4), color = Color3.fromRGB(255, 200, 70), name = "FlowerB" },
			{ shape = "Block", size = Vector3.new(5.4, 1.0, 1.4), offset = Vector3.new(0, -2.9, 0), color = Color3.fromRGB(140, 158, 78), name = "Soles" },
		},
	}),
}

BrainrotDefs.ById = {}
for _, def in ipairs(BrainrotDefs.Cast) do
	BrainrotDefs.ById[def.id] = def
end

function BrainrotDefs.Get(id)
	return BrainrotDefs.ById[id]
end

function BrainrotDefs.RarityRank(rarity)
	for index, name in ipairs(BrainrotDefs.RarityOrder) do
		if name == rarity then
			return index
		end
	end
	return 1
end

-- The shop is ordered by rarity, then by rate, so the next tier is always a
-- step up from the last.
table.sort(BrainrotDefs.Cast, function(a, b)
	local ra = BrainrotDefs.RarityRank(a.rarity)
	local rb = BrainrotDefs.RarityRank(b.rarity)
	if ra ~= rb then
		return ra < rb
	end
	return a.rate < b.rate
end)

function BrainrotDefs.NextTier(id)
	for index, def in ipairs(BrainrotDefs.Cast) do
		if def.id == id then
			return BrainrotDefs.Cast[index + 1]
		end
	end
	return nil
end

function BrainrotDefs.RollMutation(random)
	local roll = random:NextNumber()
	local cumulative = 0
	for name, chance in pairs(BrainrotDefs.Mutations) do
		cumulative += chance
		if roll < chance then
			return name
		end
	end
	return nil
end

return BrainrotDefs
