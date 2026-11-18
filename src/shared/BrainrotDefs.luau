-- BrainrotDefs: the cast. Eleven invented meme creatures on a five-step
-- rarity ladder. Each entry carries its economy numbers (rate, unlock tier)
-- and the palette + body recipe the model builder turns into parts. Nothing
-- here touches instances, so both server and client can read it safely.

local BrainrotDefs = {}

BrainrotDefs.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

BrainrotDefs.RarityColors = {
	Common = Color3.fromRGB(176, 190, 197),
	Rare = Color3.fromRGB(86, 156, 255),
	Epic = Color3.fromRGB(178, 102, 255),
	Legendary = Color3.fromRGB(255, 176, 32),
	Mythic = Color3.fromRGB(255, 84, 144),
}

-- Ordered by price: the shop and the conveyor both walk this list.
BrainrotDefs.List = {
	{
		id = "cucumber",
		name = "Sir Cucumber von Crunch",
		rarity = "Common",
		rate = 2,
		price = 50,
		shape = "cucumber",
		bodyColor = Color3.fromRGB(86, 178, 84),
		accentColor = Color3.fromRGB(242, 214, 72),
		blurb = "Knighted for services to salad.",
	},
	{
		id = "capybara",
		name = "Capybara Chef Bebek",
		rarity = "Common",
		rate = 4,
		price = 140,
		shape = "capybara",
		bodyColor = Color3.fromRGB(150, 110, 74),
		accentColor = Color3.fromRGB(248, 248, 248),
		blurb = "Grills anything. Even the menu.",
	},
	{
		id = "toilet",
		name = "Skibidi Toilet Trumpet",
		rarity = "Rare",
		rate = 9,
		price = 420,
		shape = "toilet",
		bodyColor = Color3.fromRGB(238, 238, 242),
		accentColor = Color3.fromRGB(126, 200, 255),
		blurb = "Plays the anthem of the bathroom.",
	},
	{
		id = "durian",
		name = "Durian DJ Dropbeat",
		rarity = "Rare",
		rate = 16,
		price = 1100,
		shape = "durian",
		bodyColor = Color3.fromRGB(196, 202, 92),
		accentColor = Color3.fromRGB(255, 96, 156),
		blurb = "Smells like the bass drop.",
	},
	{
		id = "flamingo",
		name = "Flamingo Flamenco Karl",
		rarity = "Epic",
		rate = 30,
		price = 2600,
		shape = "flamingo",
		bodyColor = Color3.fromRGB(255, 156, 190),
		accentColor = Color3.fromRGB(255, 232, 120),
		blurb = "Dances on one leg for tips.",
	},
	{
		id = "pizzarat",
		name = "Pizza Rat Nomnom",
		rarity = "Epic",
		rate = 55,
		price = 5200,
		shape = "rat",
		bodyColor = Color3.fromRGB(148, 148, 158),
		accentColor = Color3.fromRGB(255, 196, 64),
		blurb = "Carries a whole slice. Respect.",
	},
	{
		id = "granny",
		name = "Granny Giga Garbanzo",
		rarity = "Epic",
		rate = 90,
		price = 9500,
		shape = "granny",
		bodyColor = Color3.fromRGB(232, 196, 142),
		accentColor = Color3.fromRGB(196, 88, 148),
		blurb = "Beans older than the server.",
	},
	{
		id = "snowman",
		name = "Sigma Snowman Supreme",
		rarity = "Legendary",
		rate = 180,
		price = 19000,
		shape = "snowman",
		bodyColor = Color3.fromRGB(246, 250, 255),
		accentColor = Color3.fromRGB(40, 40, 52),
		blurb = "Melts only for the grind.",
	},
	{
		id = "toaster",
		name = "Toaster Titan Chungus",
		rarity = "Legendary",
		rate = 340,
		price = 38000,
		shape = "toaster",
		bodyColor = Color3.fromRGB(212, 214, 220),
		accentColor = Color3.fromRGB(255, 128, 48),
		blurb = "Launches toast into low orbit.",
	},
	{
		id = "moonmonkey",
		name = "Moon Monkey Bananini",
		rarity = "Mythic",
		rate = 700,
		price = 72000,
		shape = "monkey",
		bodyColor = Color3.fromRGB(128, 92, 62),
		accentColor = Color3.fromRGB(255, 226, 96),
		blurb = "Owns the banana futures market.",
	},
	{
		id = "cabbage",
		name = "Quantum Cabbage Oracle",
		rarity = "Mythic",
		rate = 1400,
		price = 130000,
		shape = "cabbage",
		bodyColor = Color3.fromRGB(148, 210, 118),
		accentColor = Color3.fromRGB(122, 226, 255),
		blurb = "Sees every timeline. Mostly leaves.",
	},
}

BrainrotDefs.ById = {}
for index, def in ipairs(BrainrotDefs.List) do
	BrainrotDefs.ById[def.id] = def
	def.index = index
end

function BrainrotDefs.get(id: string)
	return BrainrotDefs.ById[id]
end

function BrainrotDefs.rarityRank(rarity: string): number
	for i, value in ipairs(BrainrotDefs.RarityOrder) do
		if value == rarity then
			return i
		end
	end
	return 0
end

return BrainrotDefs
