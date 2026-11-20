-- Shared tuning. The early loop is deliberately generous: a new player gets a free
-- starter brainrot on their plot and enough cash to grab a second within seconds, while
-- the late rebirth/Mythic prices keep the long climb intact.
local Config = {}

Config.World = {
	groundSize = 380,
	conveyorWidth = 17,
	conveyorLength = 78,
	conveyorStartZ = -46,
	conveyorDeckY = 2.2,
	spawnPosition = Vector3.new(0, 4, 52),
	plotCenters = {
		Vector3.new(-64, 0, -46),
		Vector3.new(-64, 0, -4),
		Vector3.new(-64, 0, 38),
		Vector3.new(64, 0, -46),
		Vector3.new(64, 0, -4),
		Vector3.new(64, 0, 38),
	},
	plotHalfWidth = 17,
	plotHalfDepth = 13,
	-- Six pads per plot in a 3x2 grid, so a base fills up quickly and reads as busy.
	slotOffsets = {
		Vector3.new(-11, 0, -6),
		Vector3.new(0, 0, -6),
		Vector3.new(11, 0, -6),
		Vector3.new(-11, 0, 6),
		Vector3.new(0, 0, 6),
		Vector3.new(11, 0, 6),
	},
	slotPadSize = Vector3.new(8, 0.5, 8),
	labelStudsOffset = Vector3.new(0, 3.4, 0),
}

Config.Conveyor = {
	npcCount = 6,
	speed = 2.6,
	spacing = 12,
	respawnDelay = 0.8,
	buyDistance = 34,
	starterGrant = true,
}

Config.Economy = {
	startingMoney = 120,
	incomeTickSeconds = 1,
	rebirthBaseCost = 1500,
	rebirthCostGrowth = 3.4,
	rebirthBonus = 0.75,
	lockCost = 300,
	lockSeconds = 90,
	stealCooldown = 8,
	wavePenaltyShare = 0.25,
}

Config.Wave = {
	firstCalmSeconds = 30,
	calmSeconds = 26,
	warningSeconds = 12,
	sweepSeconds = 10,
	doubleSeconds = 20,
	wallHalfExtent = 165,
	wallStartX = -168,
	wallEndX = 168,
	homeGraceSeconds = 1.5,
}

Config.Mutation = {
	goldenChance = 0.12,
	diamondChance = 0.04,
	goldenRate = 2.5,
	diamondRate = 5,
	goldenColor = Color3.fromRGB(255, 196, 48),
	diamondColor = Color3.fromRGB(118, 226, 255),
}

Config.Keys = {
	rebirth = Enum.KeyCode.R,
	lock = Enum.KeyCode.L,
	buy = Enum.KeyCode.B,
}

return Config
