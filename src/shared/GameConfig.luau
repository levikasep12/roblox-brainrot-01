-- Every tuning value for Brainrot Rush in one table.

local GameConfig = {}

GameConfig.GameName = "Brainrot Rush"
GameConfig.StartingMoney = 250
GameConfig.StartingSlots = 6
GameConfig.SnapshotInterval = 0.2

GameConfig.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

GameConfig.RarityColors = {
	Common = Color3.fromRGB(196, 203, 214),
	Rare = Color3.fromRGB(84, 160, 255),
	Epic = Color3.fromRGB(178, 105, 255),
	Legendary = Color3.fromRGB(255, 176, 46),
	Mythic = Color3.fromRGB(255, 76, 132),
}

-- The belt brainrots walk across, west to east.
GameConfig.Conveyor = {
	startX = -74,
	endX = 76,
	y = 1.6,
	walkSpeed = 6.4,
	spawnInterval = 4.2,
	maxOnBelt = 12,
	pickupRange = 24,
}

GameConfig.Mutations = {
	{
		id = "Normal",
		label = "",
		chance = 0.9,
		rateMultiplier = 1,
		priceMultiplier = 1,
		color = Color3.fromRGB(235, 235, 235),
	},
	{
		id = "Golden",
		label = "GOLDEN",
		chance = 0.084,
		rateMultiplier = 2.5,
		priceMultiplier = 2.4,
		color = Color3.fromRGB(255, 199, 51),
	},
	{
		id = "Diamond",
		label = "DIAMOND",
		chance = 0.016,
		rateMultiplier = 7,
		priceMultiplier = 5,
		color = Color3.fromRGB(112, 232, 255),
	},
}

GameConfig.Rebirth = {
	baseCost = 1200,
	costGrowth = 2.45,
	maxRebirths = 30,
	multiplierPerRebirth = 0.25,
}

GameConfig.Lock = {
	cost = 350,
	duration = 60,
}

GameConfig.Steal = {
	range = 34,
	cooldown = 2.2,
	rivalAlarmChance = 0.25,
	rivalAlarmPenalty = 0.1,
	victimAlert = true,
}

GameConfig.Hazard = {
	firstDelay = 70,
	interval = 105,
	warningSeconds = 7,
	travelSeconds = 20,
	startZ = -125,
	endZ = 125,
	safeRadius = 24,
	lossFraction = 0.15,
	incomeBoost = 2,
	hitRange = 5,
}

GameConfig.Dash = {
	walkSpeed = 34,
	duration = 2.4,
	cooldown = 10,
}

GameConfig.Rival = {
	restockInterval = 16,
	maxSlots = 6,
	names = { "Pigeon Cartel", "Toilet Syndicate" },
}

GameConfig.BeltRarityWeights = {
	Common = 46,
	Rare = 27,
	Epic = 16,
	Legendary = 8,
	Mythic = 3,
}

return GameConfig
