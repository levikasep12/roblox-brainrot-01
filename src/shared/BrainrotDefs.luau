-- The cast: eleven hand-built brainrots, their rarity, price and money per second.
-- Every model is assembled from plain Parts in BrainrotModel, so no uploaded asset is needed.

local GameConfig = require(script.Parent.GameConfig)

local BrainrotDefs = {}

BrainrotDefs.List = {
	{
		id = "capybara_chef",
		name = "Capybara Chef",
		rarity = "Common",
		rate = 2,
		price = 60,
		builder = "capybaraChef",
		blurb = "Stirs the soup. Has never blinked once.",
		accent = Color3.fromRGB(160, 120, 80),
	},
	{
		id = "durian_dj",
		name = "Durian DJ",
		rarity = "Common",
		rate = 3.5,
		price = 115,
		builder = "durianDj",
		blurb = "Drops beats and a very strong smell.",
		accent = Color3.fromRGB(186, 200, 70),
	},
	{
		id = "skibidi_toaster",
		name = "Skibidi Toaster",
		rarity = "Common",
		rate = 5,
		price = 180,
		builder = "skibidiToaster",
		blurb = "Pops toast at 4 a.m. on purpose.",
		accent = Color3.fromRGB(210, 216, 225),
	},
	{
		id = "cucumber_cowboy",
		name = "Cucumber Cowboy",
		rarity = "Rare",
		rate = 12,
		price = 540,
		builder = "cucumberCowboy",
		blurb = "Rides a very small tumbleweed.",
		accent = Color3.fromRGB(96, 178, 96),
	},
	{
		id = "flamingo_accountant",
		name = "Flamingo Accountant",
		rarity = "Rare",
		rate = 18,
		price = 820,
		builder = "flamingoAccountant",
		blurb = "Claims the pink is a tax write-off.",
		accent = Color3.fromRGB(255, 132, 176),
	},
	{
		id = "croissant_cactus",
		name = "Croissant Cactus",
		rarity = "Epic",
		rate = 45,
		price = 2900,
		builder = "croissantCactus",
		blurb = "Flaky, spiky, and mildly judgmental.",
		accent = Color3.fromRGB(226, 187, 104),
	},
	{
		id = "raccoon_lawyer",
		name = "Raccoon Lawyer",
		rarity = "Epic",
		rate = 65,
		price = 4200,
		builder = "raccoonLawyer",
		blurb = "Will sue you for looking at the trash.",
		accent = Color3.fromRGB(126, 132, 142),
	},
	{
		id = "toilet_wizard",
		name = "Toilet Wizard",
		rarity = "Legendary",
		rate = 160,
		price = 13500,
		builder = "toiletWizard",
		blurb = "Casts Flush. It is super effective.",
		accent = Color3.fromRGB(120, 214, 255),
	},
	{
		id = "pigeon_overlord",
		name = "Pigeon Overlord",
		rarity = "Legendary",
		rate = 230,
		price = 19500,
		builder = "pigeonOverlord",
		blurb = "Owns every statue in the city.",
		accent = Color3.fromRGB(150, 160, 178),
	},
	{
		id = "mango_mafia_don",
		name = "Mango Mafia Don",
		rarity = "Mythic",
		rate = 700,
		price = 72000,
		builder = "mangoMafiaDon",
		blurb = "Makes offers you cannot refuse. Sweetly.",
		accent = Color3.fromRGB(255, 146, 48),
	},
	{
		id = "banana_bureaucrat",
		name = "Banana Bureaucrat",
		rarity = "Mythic",
		rate = 1000,
		price = 110000,
		builder = "bananaBureaucrat",
		blurb = "Your form is missing one more form.",
		accent = Color3.fromRGB(245, 216, 84),
	},
}

BrainrotDefs.ById = {}
BrainrotDefs.ByRarity = {}

for _, def in ipairs(BrainrotDefs.List) do
	BrainrotDefs.ById[def.id] = def
	BrainrotDefs.ByRarity[def.rarity] = BrainrotDefs.ByRarity[def.rarity] or {}
	table.insert(BrainrotDefs.ByRarity[def.rarity], def)
end

function BrainrotDefs.get(defId: string)
	return BrainrotDefs.ById[defId]
end

function BrainrotDefs.rarityIndex(rarity: string): number
	for index, name in ipairs(GameConfig.RarityOrder) do
		if name == rarity then
			return index
		end
	end
	return 0
end

function BrainrotDefs.rarityColor(rarity: string): Color3
	return GameConfig.RarityColors[rarity] or Color3.fromRGB(200, 200, 200)
end

function BrainrotDefs.mutationInfo(mutationId: string)
	for _, mutation in ipairs(GameConfig.Mutations) do
		if mutation.id == mutationId then
			return mutation
		end
	end
	return GameConfig.Mutations[1]
end

function BrainrotDefs.rollMutation(): string
	local roll = math.random()
	local accumulated = 0
	for _, mutation in ipairs(GameConfig.Mutations) do
		accumulated += mutation.chance
		if roll <= accumulated then
			return mutation.id
		end
	end
	return GameConfig.Mutations[1].id
end

function BrainrotDefs.rateFor(def, mutationId: string): number
	local mutation = BrainrotDefs.mutationInfo(mutationId)
	return def.rate * mutation.rateMultiplier
end

function BrainrotDefs.priceFor(def, mutationId: string): number
	local mutation = BrainrotDefs.mutationInfo(mutationId)
	return math.floor(def.price * mutation.priceMultiplier)
end

function BrainrotDefs.displayName(def, mutationId: string): string
	local mutation = BrainrotDefs.mutationInfo(mutationId)
	if mutation.label == "" then
		return def.name
	end
	return mutation.label .. " " .. def.name
end

function BrainrotDefs.pickWeightedRarity(): string
	local total = 0
	for _, rarity in ipairs(GameConfig.RarityOrder) do
		total += GameConfig.BeltRarityWeights[rarity] or 0
	end
	local roll = math.random() * total
	local accumulated = 0
	for _, rarity in ipairs(GameConfig.RarityOrder) do
		accumulated += GameConfig.BeltRarityWeights[rarity] or 0
		if roll <= accumulated then
			return rarity
		end
	end
	return "Common"
end

function BrainrotDefs.randomForRarity(rarity: string)
	local pool = BrainrotDefs.ByRarity[rarity]
	if not pool or #pool == 0 then
		pool = BrainrotDefs.ByRarity.Common
	end
	return pool[math.random(1, #pool)]
end

function BrainrotDefs.randomDef()
	return BrainrotDefs.randomForRarity(BrainrotDefs.pickWeightedRarity())
end

return BrainrotDefs
