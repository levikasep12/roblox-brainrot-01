-- Config: every tuning number and world coordinate the game shares.
-- Money, timing and layout live here so the server and the HUD agree, and so
-- balancing the game never means hunting through gameplay code.

local Config = {}

Config.GameName = "BRAINROT RUSH"
Config.StartingMoney = 75
Config.MaxSlots = 6
Config.PlotCount = 6
Config.SlotOffsets = {
	Vector3.new(-12, 0, -8),
	Vector3.new(0, 0, -8),
	Vector3.new(12, 0, -8),
	Vector3.new(-12, 0, 8),
	Vector3.new(0, 0, 8),
	Vector3.new(12, 0, 8),
}
Config.PlotSize = 44
Config.PlotPositions = {
	Vector3.new(-58, 0, -44),
	Vector3.new(0, 0, -48),
	Vector3.new(58, 0, -44),
	Vector3.new(-58, 0, 44),
	Vector3.new(0, 0, 48),
	Vector3.new(58, 0, 44),
}
Config.BaseRadius = 30 -- how close a player must be to their plot to "be home"

Config.RebirthBaseCost = 1500
Config.RebirthGrowth = 1.8
Config.RebirthMultiplierStep = 0.25

Config.LockCost = 250
Config.LockDuration = 60
Config.StealCooldown = 6

Config.SpawnInterval = 4.5
Config.MaxConveyor = 4
Config.ConveyorStartX = -72
Config.ConveyorEndX = 72
Config.ConveyorZ = 0
Config.ConveyorHeight = 2.6
Config.WalkSpeed = 4.5

Config.WaveWarning = 12
Config.WaveSweep = 8
Config.WaveCooldown = 25
Config.WaveIdle = 35
Config.WaveX2Duration = 20
Config.WaveWallStartX = 120
Config.WaveWallEndX = -120

Config.ShopPosition = Vector3.new(0, 0, 88)
Config.SpawnPosition = Vector3.new(0, 3, 70)

Config.MutationChance = 0.13
Config.DiamondChance = 0.03

function Config.rebirthCost(rebirths: number): number
	return math.floor(Config.RebirthBaseCost * (Config.RebirthGrowth ^ rebirths))
end

function Config.rebirthMultiplier(rebirths: number): number
	return 1 + rebirths * Config.RebirthMultiplierStep
end

return Config
