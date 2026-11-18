-- The brainrot cast: every character, its rarity ladder rung, its shop price and
-- its money-per-second rate. Pure data, shared by server and client so the shop
-- and the 3D models always agree.

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
BrainrotDefs.Cast = {
	{
		id = "capybara_chef",
		name = "Capybara Chef",
		rarity = "Common",
		price = 50,
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
		price = 110,
		rate = 3,
		shape = "box",
		prop = "antenna",
		bodyColor = Color3.fromRGB(206, 210, 216),
		accentColor = Color3.fromRGB(255, 96, 70),
	},
	{
		id = "durian_dj",
		name = "Durian DJ",
		rarity = "Rare",
		price = 260,
		rate = 6,
		shape = "round",
		prop = "headphones",
		bodyColor = Color3.fromRGB(150, 178, 66),
		accentColor = Color3.fromRGB(42, 42, 52),
	},
	{
		id = "pigeon_landlord",
		name = "Pigeon Landlord",
		rarity = "Rare",
		price = 480,
		rate = 9,
		shape = "round",
		prop = "tophat",
		bodyColor = Color3.fromRGB(132, 144, 166),
		accentColor = Color3.fromRGB(64, 44, 34),
	},
	{
		id = "sloth_barista",
		name = "Sloth Barista",
		rarity = "Rare",
		price = 760,
		rate = 13,
		shape = "round",
		prop = "cup",
		bodyColor = Color3.fromRGB(146, 122, 100),
		accentColor = Color3.fromRGB(240, 226, 198),
	},
	{
		id = "moth_accountant",
		name = "Moth Accountant",
		rarity = "Epic",
		price = 1200,
		rate = 24,
		shape = "round",
		prop = "wings",
		bodyColor = Color3.fromRGB(214, 198, 150),
		accentColor = Color3.fromRGB(120, 108, 74),
	},
	{
		id = "croissant_sensei",
		name = "Croissant Sensei",
		rarity = "Epic",
		price = 1900,
		rate = 38,
		shape = "round",
		prop = "headband",
		bodyColor = Color3.fromRGB(226, 168, 88),
		accentColor = Color3.fromRGB(210, 62, 62),
	},
	{
		id = "tax_goose",
		name = "Tax Evasion Goose",
		rarity = "Epic",
		price = 3000,
		rate = 58,
		shape = "round",
		prop = "briefcase",
		bodyColor = Color3.fromRGB(246, 246, 238),
		accentColor = Color3.fromRGB(58, 100, 172),
	},
	{
		id = "flamingo_voidwalker",
		name = "Flamingo Voidwalker",
		rarity = "Legendary",
		price = 5200,
		rate = 95,
		shape = "round",
		prop = "halo",
		bodyColor = Color3.fromRGB(255, 122, 172),
		accentColor = Color3.fromRGB(122, 84, 255),
	},
	{
		id = "cucumber_oracle",
		name = "Cucumber Oracle",
		rarity = "Legendary",
		price = 8500,
		rate = 150,
		shape = "box",
		prop = "crown",
		bodyColor = Color3.fromRGB(94, 176, 96),
		accentColor = Color3.fromRGB(255, 214, 64),
	},
	{
		id = "disco_walrus",
		name = "Disco Walrus Prime",
		rarity = "Mythic",
		price = 15000,
		rate = 260,
		shape = "round",
		prop = "disco",
		bodyColor = Color3.fromRGB(122, 132, 168),
		accentColor = Color3.fromRGB(255, 92, 214),
	},
	{
		id = "traffic_cone_sage",
		name = "Sentient Traffic Cone",
		rarity = "Mythic",
		price = 26000,
		rate = 420,
		shape = "cone",
		prop = "glasses",
		bodyColor = Color3.fromRGB(255, 124, 42),
		accentColor = Color3.fromRGB(246, 246, 246),
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

function BrainrotDefs.rarityRank(rarity)
	for index, name in ipairs(BrainrotDefs.RarityOrder) do
		if name == rarity then
			return index
		end
	end
	return 1
end

return BrainrotDefs
