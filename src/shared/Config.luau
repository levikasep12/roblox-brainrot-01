local Config = {}

Config.World = {
	groundSize = 380,
	conveyorWidth = 17,
	conveyorLength = 78,
	conveyorStartZ = -46,
	conveyorDeckY = 2.2,
	spawnPosition = Vector3.new(0, 4, 58),
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
	slotOffsets = {
		Vector3.new(-7, 0, -5.5),
		Vector3.new(7, 0, -5.5),
		Vector3.new(-7, 0, 5.5),
		Vector3.new(7, 0, 5.5),
	},
	slotPadSize = Vector3.new(9, 0.5, 9),
	labelStudsOffset = Vector3.new(0, 3.4, 0),
}

Config.Conveyor = {
	npcCount = 5,
	speed = 3.4,
	spacing = 13,
	respawnDelay = 1.4,
	buyDistance = 34,
}

Config.Economy = {
	startingMoney = 60,
	incomeTickSeconds = 1,
	rebirthBaseCost = 2500,
	rebirthCostGrowth = 3.4,
	rebirthBonus = 0.75,
	lockCost = 300,
	lockSeconds = 90,
	stealCooldown = 8,
	wavePenaltyShare = 0.25,
}

Config.Wave = {
	firstCalmSeconds = 28,
	calmSeconds = 34,
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
