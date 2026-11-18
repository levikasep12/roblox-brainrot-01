-- Where the eight base plots sit around the conveyor. Six player plots in two
-- rows face the belt; two rival crews hold the south-east corners. facing is
-- +1 when the plot looks toward +Z, -1 when it looks toward -Z.

local PlotLayout = {}

PlotLayout.SlotCount = 6
PlotLayout.SlotOffsets = {
	Vector3.new(-10, 0, -5),
	Vector3.new(0, 0, -5),
	Vector3.new(10, 0, -5),
	Vector3.new(-10, 0, 6),
	Vector3.new(0, 0, 6),
	Vector3.new(10, 0, 6),
}

PlotLayout.Plots = {
	{ index = 1, name = "Plot 1", kind = "player", center = Vector3.new(-80, 0, -36), facing = 1 },
	{ index = 2, name = "Plot 2", kind = "player", center = Vector3.new(-28, 0, -36), facing = 1 },
	{ index = 3, name = "Plot 3", kind = "player", center = Vector3.new(24, 0, -36), facing = 1 },
	{ index = 4, name = "Plot 4", kind = "player", center = Vector3.new(76, 0, -36), facing = 1 },
	{ index = 5, name = "Plot 5", kind = "player", center = Vector3.new(-80, 0, 36), facing = -1 },
	{ index = 6, name = "Plot 6", kind = "player", center = Vector3.new(-28, 0, 36), facing = -1 },
	{ index = 7, name = "Rival Base A", kind = "rival", center = Vector3.new(24, 0, 36), facing = -1 },
	{ index = 8, name = "Rival Base B", kind = "rival", center = Vector3.new(76, 0, 36), facing = -1 },
}

PlotLayout.PlayerPlotIndexes = { 1, 2, 3, 4, 5, 6 }
PlotLayout.RivalPlotIndexes = { 7, 8 }

function PlotLayout.get(plotIndex: number)
	return PlotLayout.Plots[plotIndex]
end

function PlotLayout.slotPosition(plotIndex: number, slotIndex: number): Vector3
	local plot = PlotLayout.Plots[plotIndex]
	local offset = PlotLayout.SlotOffsets[slotIndex]
	if not plot or not offset then
		return Vector3.new(0, 3, 0)
	end
	return plot.center + Vector3.new(offset.X, 1.58, offset.Z)
end

function PlotLayout.spawnPosition(plotIndex: number): Vector3
	local plot = PlotLayout.Plots[plotIndex]
	if not plot then
		return Vector3.new(0, 4, 0)
	end
	return plot.center + Vector3.new(0, 3.6, (plot.facing or 1) * 10)
end

function PlotLayout.isInside(plotIndex: number, position: Vector3, radius: number): boolean
	local plot = PlotLayout.Plots[plotIndex]
	if not plot then
		return false
	end
	local flatDistance = (Vector2.new(position.X, position.Z) - Vector2.new(plot.center.X, plot.center.Z)).Magnitude
	return flatDistance <= (radius or 26)
end

return PlotLayout
