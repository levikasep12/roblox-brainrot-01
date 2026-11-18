-- Shared tuning for Brainrot Rush. One table so server and client agree on
-- prices, plot positions, wave timing and the conveyor path.

local Config = {}

Config.GameName = "BRAINROT RUSH"
Config.StartingMoney = 260
Config.SlotsPerPlot = 6
Config.PlotCount = 6
Config.PlotSize = 34
Config.MaxConveyorOffers = 7
Config.ConveyorSpawnInterval = 5.5
Config.ConveyorSpeed = 5.2
Config.ConveyorStartZ = -58
Config.ConveyorEndZ = 58
Config.ConveyorTopY = 4.1
Config.ConveyorHalfWidth = 6

-- Plot centres, left column then right column. Index 1..6.
Config.PlotCenters = {
	Vector3.new(-50, 0, -42),
	Vector3.new(-50, 0, 0),
	Vector3.new(-50, 0, 42),
	Vector3.new(50, 0, -42),
	Vector3.new(50, 0, 0),
	Vector3.new(50, 0, 42),
}

-- Slot pads inside a plot, relative to the plot centre. Feet of a housed
-- brainrot rest a little above the pad.
Config.SlotOffsets = {
	Vector3.new(-9, 0, -8),
	Vector3.new(0, 0, -8),
	Vector3.new(9, 0, -8),
	Vector3.new(-9, 0, 8),
	Vector3.new(0, 0, 8),
	Vector3.new(9, 0, 8),
}
Config.SlotPadSize = 8.4
Config.PlotTopY = 1
-- How thick a slot pad is. It sits on the plot deck, and a housed brainrot's
-- feet rest on its top face, so SlotPosition adds this to PlotTopY.
Config.SlotPadHeight = 0.5
Config.ShopPosition = Vector3.new(0, 0, 112)
Config.SpawnPosition = Vector3.new(0, 0, 80)
Config.SpawnPlazaSize = Vector2.new(60, 26)
Config.AltarPosition = Vector3.new(0, 0, -96)

Config.RebirthBaseCost = 2500
Config.RebirthCostGrowth = 3
Config.RebirthMultiplierPerLevel = 0.75

Config.LockCost = 500
Config.LockDuration = 45
Config.StealCooldown = 12

Config.WaveFirstDelay = 40
Config.WaveIntervalMin = 60
Config.WaveIntervalMax = 85
Config.WaveWarningTime = 8
Config.WaveTravelTime = 10
Config.WaveMoneyLoss = 0.1
Config.WaveDamage = 12

Config.MutationChance = {
	Golden = 0.08,
	Diamond = 0.025,
}

Config.DemoRivals = {
	{ plotIndex = 5, name = "Rival Ray", brainrots = { "bananaconda", "skibidi_toaster" } },
	{ plotIndex = 6, name = "Grandma Greta", brainrots = { "waffle_wizard", "durian_dj" } },
}

function Config.RebirthCost(rebirths)
	return math.floor(Config.RebirthBaseCost * (Config.RebirthCostGrowth ^ rebirths) + 0.5)
end

function Config.MultiplierFor(rebirths)
	return 1 + Config.RebirthMultiplierPerLevel * rebirths
end

function Config.PlotCenter(plotIndex)
	return Config.PlotCenters[plotIndex] or Config.PlotCenters[1]
end

-- Where a housed brainrot's feet go: centred on its pad, resting on the pad's
-- top face rather than sunk into the plot deck.
function Config.SlotPosition(plotIndex, slotIndex)
	local center = Config.PlotCenter(plotIndex)
	local offset = Config.SlotOffsets[slotIndex] or Vector3.zero
	return center + offset + Vector3.new(0, Config.PlotTopY + Config.SlotPadHeight, 0)
end

-- Which way a housed brainrot faces: toward the middle of the map, so a
-- player walking the central path sees the fronts of every base.
function Config.SlotFacing(plotIndex)
	local center = Config.PlotCenter(plotIndex)
	local toward = Vector3.new(0, 0, 0) - Vector3.new(center.X, 0, center.Z)
	if toward.Magnitude < 0.001 then
		return Vector3.new(0, 0, 1)
	end
	return toward.Unit
end

function Config.IsInsidePlot(position, plotIndex)
	local center = Config.PlotCenter(plotIndex)
	local half = Config.PlotSize * 0.5
	return math.abs(position.X - center.X) <= half
		and math.abs(position.Z - center.Z) <= half
		and position.Y <= 22
end

return Config
