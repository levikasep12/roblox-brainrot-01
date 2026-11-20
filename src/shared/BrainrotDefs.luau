-- The brainrot cast: every character, its rarity ladder rung, its shop price and
-- its money-per-second rate. Pure data, shared by server and client so the shop
-- and the 3D models always agree.
-- Sixteen characters across five rarities: the first two are priced so a brand
-- new player can buy one within seconds, while the Mythic rung stays a long climb.

local BrainrotDefs = {}

BrainrotDefs.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

BrainrotDefs.RarityColors = {
	Common = Color3.fromRGB(176, 190, 197),
	Rare = Color3.fromRGB(86, 156, 255),
	Epic = Color3.fromRGB(186, 104, 255),
	Legendary = Color3.fromRGB(255, 170, 48),
	Mythic = Color3.fromRGB(255, 84, 132),
}

-- rate = money per second at one plot slot; price = shop cost in dollars.
-- The ladder is deliberately steep after the first rung: cheap starters, costly Mythics.
BrainrotDefs.Cast = {
	{
		id = "capybara_chef",
		name = "Capybara Chef",
		rarity = "Common",
		price = 25,
		rate = 1,
		shape = "round",
		prop = "chefhat",
		bodyColor = Color3.fromRGB(158, 120, 78),
		accentColor = Color3.fromRGB(250, 250, 245),
	},
	{
		id = "toaster_prophet",
		name = "Toaster Prophet",
		rarity = "Common",
		price = 60,
		rate = 3,
		shape = "box",
		prop = "antenna",
		bodyColor = Color3.fromRGB(206, 210, 216),
		accentColor = Color3.fromRGB(255, 96, 70),
	},
	{
		id = "sentient_sock",
		name = "Sentient Sock",
		rarity = "Common",
		price = 120,
		rate = 5,
		shape = "box",
		prop = "stripes",
		bodyColor = Color3.fromRGB(238, 238, 242),
		accentColor = Color3.fromRGB(96, 132, 220),
	},
	{
		id = "drama_llama",
		name = "Drama Llama",
		rarity = "Common",
		price = 200,
		rate = 8,
		shape = "round",
		prop = "scarf",
		bodyColor = Color3.fromRGB(226, 196, 150),
		accentColor = Color3.fromRGB(228, 68, 96),
	},
	{
		id = "durian_dj",
		name = "Durian DJ",
		rarity = "Rare",
		price = 340,
		rate = 13,
		shape = "round",
		prop = "headphones",
		bodyColor = Color3.fromRGB(150, 178, 66),
		accentColor = Color3.fromRGB(42, 42, 52),
	},
	{
		id = "pigeon_landlord",
		name = "Pigeon Landlord",
		rarity = "Rare",
		price = 560,
		rate = 20,
		shape = "round",
		prop = "tophat",
		bodyColor = Color3.fromRGB(132, 144, 166),
		accentColor = Color3.fromRGB(64, 44, 34),
	},
	{
		id = "sloth_barista",
		name = "Sloth Barista",
		rarity = "Rare",
		price = 900,
		rate = 30,
		shape = "round",
		prop = "cup",
		bodyColor = Color3.fromRGB(146, 122, 100),
		accentColor = Color3.fromRGB(240, 226, 198),
	},
	{
		id = "moth_accountant",
		name = "Moth Accountant",
		rarity = "Epic",
		price = 1500,
		rate = 48,
		shape = "round",
		prop = "wings",
		bodyColor = Color3.fromRGB(214, 198, 150),
		accentColor = Color3.fromRGB(120, 108, 74),
	},
	{
		id = "croissant_sensei",
		name = "Croissant Sensei",
		rarity = "Epic",
		price = 2400,
		rate = 72,
		shape = "round",
		prop = "headband",
		bodyColor = Color3.fromRGB(226, 168, 88),
		accentColor = Color3.fromRGB(210, 62, 62),
	},
	{
		id = "tax_goose",
		name = "Tax Evasion Goose",
		rarity = "Epic",
		price = 3800,
		rate = 110,
		shape = "round",
		prop = "briefcase",
		bodyColor = Color3.fromRGB(246, 246, 238),
		accentColor = Color3.fromRGB(58, 100, 172),
	},
	{
		id = "flamingo_voidwalker",
		name = "Flamingo Voidwalker",
		rarity = "Legendary",
		price = 6200,
		rate = 175,
		shape = "round",
		prop = "halo",
		bodyColor = Color3.fromRGB(255, 122, 172),
		accentColor = Color3.fromRGB(122, 84, 255),
	},
	{
		id = "cucumber_oracle",
		name = "Cucumber Oracle",
		rarity = "Legendary",
		price = 9800,
		rate = 260,
		shape = "box",
		prop = "crown",
		bodyColor = Color3.fromRGB(94, 176, 96),
		accentColor = Color3.fromRGB(255, 214, 64),
	},
	{
		id = "skibidi_pope",
		name = "Skibidi Toilet Pope",
		rarity = "Legendary",
		price = 15000,
		rate = 390,
		shape = "box",
		prop = "mitre",
		bodyColor = Color3.fromRGB(240, 240, 246),
		accentColor = Color3.fromRGB(255, 210, 84),
	},
	{
		id = "disco_walrus",
		name = "Disco Walrus Prime",
		rarity = "Mythic",
		price = 24000,
		rate = 600,
		shape = "round",
		prop = "disco",
		bodyColor = Color3.fromRGB(122, 132, 168),
		accentColor = Color3.fromRGB(255, 92, 214),
	},
	{
		id = "traffic_cone_sage",
		name = "Sentient Traffic Cone",
		rarity = "Mythic",
		price = 38000,
		rate = 920,
		shape = "cone",
		prop = "glasses",
		bodyColor = Color3.fromRGB(255, 124, 42),
		accentColor = Color3.fromRGB(246, 246, 246),
	},
	{
		id = "ohio_final_boss",
		name = "Ohio Final Boss",
		rarity = "Mythic",
		price = 60000,
		rate = 1400,
		shape = "cone",
		prop = "horns",
		bodyColor = Color3.fromRGB(58, 44, 84),
		accentColor = Color3.fromRGB(255, 64, 96),
	},
}

BrainrotDefs.ById = {}
for _, def in ipairs(BrainrotDefs.Cast) do
	BrainrotDefs.ById[def.id] = def
end

-- The order the shop offers them in: cheapest first, so a player climbs the ladder.
function BrainrotDefs.sortedByPrice()
	local list = table.clone(BrainrotDefs.Cast)
	table.sort(list, function(a, b)
		return a.price < b.price
	end)
	return list
end

-- The next rung above `price` the player has not afforded yet.
function BrainrotDefs.nextAfterPrice(budget)
	local sorted = BrainrotDefs.sortedByPrice()
	for _, def in ipairs(sorted) do
		if def.price > budget then
			return def
		end
	end
	return sorted[#sorted]
end

-- The cheapest brainrot on the ladder: the free starter a new player receives.
function BrainrotDefs.starter()
	return BrainrotDefs.sortedByPrice()[1]
end

function BrainrotDefs.rarityRank(rarity)
	for index, name in ipairs(BrainrotDefs.RarityOrder) do
		if name == rarity then
			return index
		end
	end
	return 1
end

return BrainrotDefs
