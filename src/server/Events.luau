-- The hazard: a neon wave sweeps the map south to north, warning first, then
-- punishing anyone caught away from their base and doubling income for the
-- players who survived it. Also runs the rival restock timer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local PlotLayout = require(ReplicatedStorage.Shared.PlotLayout)
local WorldRefs = require(ReplicatedStorage.Shared.WorldRefs)
local Store = require(script.Parent.Store)
local Bases = require(script.Parent.Bases)
local PlayerService = require(script.Parent.PlayerService)

local Events = {}

local waveModel: Model? = nil
local wavePart: BasePart? = nil
local animConnection: RBXScriptConnection? = nil

local notify: ((any, string, string) -> ())? = nil
local burst: ((any, Vector3, Color3) -> ())? = nil

function Events.setNotifier(notifier, burster)
	notify = notifier
	burst = burster
end

local function hazardWave(): Model
	if waveModel and waveModel.Parent then
		return waveModel
	end
	local parent = WorldRefs.root() or Workspace
	local existing = parent:FindFirstChild("HazardWave")
	if existing and existing:IsA("Model") then
		waveModel = existing
		wavePart = existing:FindFirstChild("Wall") :: BasePart?
		return existing
	end

	local model = Instance.new("Model")
	model.Name = "HazardWave"

	local wall = Instance.new("Part")
	wall.Name = "Wall"
	wall.Size = Vector3.new(340, 26, 3)
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanQuery = false
	wall.CanTouch = false
	wall.Material = Enum.Material.ForceField
	wall.Color = Color3.fromRGB(255, 70, 140)
	wall.Transparency = 0.35
	wall.CFrame = CFrame.new(0, 12, GameConfig.Hazard.startZ)
	wall.Parent = model

	local glow = Instance.new("Part")
	glow.Name = "Glow"
	glow.Size = Vector3.new(340, 1.4, 5)
	glow.Anchored = true
	glow.CanCollide = false
	glow.CanQuery = false
	glow.CanTouch = false
	glow.Material = Enum.Material.Neon
	glow.Color = Color3.fromRGB(255, 140, 200)
	glow.Transparency = 0.1
	glow.CFrame = CFrame.new(0, 1.2, GameConfig.Hazard.startZ)
	glow.Parent = model

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 90, 160)
	light.Brightness = 3
	light.Range = 40
	light.Parent = glow

	model.Parent = WorldRefs.root() or Workspace
	waveModel = model
	wavePart = wall
	return model
end

local function setWaveVisible(visible: boolean)
	if not waveModel then
		return
	end
	for _, child in ipairs(waveModel:GetChildren()) do
		if child:IsA("BasePart") then
			child.Transparency = if not visible then 1 elseif child.Name == "Wall" then 0.35 else 0.1
		end
	end
end

local function setWaveZ(z: number)
	if not waveModel then
		return
	end
	local wall = waveModel:FindFirstChild("Wall")
	local glow = waveModel:FindFirstChild("Glow")
	if wall then
		wall.CFrame = CFrame.new(0, 12, z)
	end
	if glow then
		glow.CFrame = CFrame.new(0, 1.2, z)
	end
end

function Events.startHazard()
	local now = os.clock()
	local hazard = Store.state.hazard
	hazard.waveIndex += 1
	hazard.phase = "warning"
	hazard.startedAt = now
	hazard.z = GameConfig.Hazard.startZ
	hazard.endsAt = now + GameConfig.Hazard.warningSeconds + GameConfig.Hazard.travelSeconds
	setWaveZ(GameConfig.Hazard.startZ)
	setWaveVisible(false)
	for _, profile in ipairs(Store.allPlayers()) do
		if notify then
			notify(profile.userId, "HAZARD WAVE INCOMING - dash to your base (Q)", "warn")
		end
		profile.lastWaveHit = 0
	end
end

local function damageCaughtPlayers()
	local hazard = Store.state.hazard
	for _, profile in ipairs(Store.allPlayers()) do
		local position = PlayerService.positionFor(profile.userId)
		if position then
			local nearWave = math.abs(position.Z - hazard.z) <= GameConfig.Hazard.hitRange
			local safe = PlayerService.isSafeAtBase(profile, position)
			if nearWave and not safe and os.clock() - profile.lastWaveHit > 3 then
				profile.lastWaveHit = os.clock()
				local lost = math.floor(profile.money * GameConfig.Hazard.lossFraction)
				profile.money = math.max(0, profile.money - lost)
				if notify then
					notify(profile.userId, "The wave caught you! -$" .. tostring(lost), "bad")
				end
				if burst then
					burst(profile.userId, position, Color3.fromRGB(255, 80, 120))
				end
			end
		end
	end
end

function Events.stepHazard(dt: number)
	local hazard = Store.state.hazard
	local now = os.clock()

	if hazard.phase == "idle" then
		if now >= hazard.nextAt then
			Events.startHazard()
		end
		return
	end

	if hazard.phase == "warning" then
		if now - hazard.startedAt >= GameConfig.Hazard.warningSeconds then
			hazard.phase = "sweeping"
			hazard.startedAt = now
			hazardWave()
			setWaveZ(GameConfig.Hazard.startZ)
			setWaveVisible(true)
			for _, profile in ipairs(Store.allPlayers()) do
				if notify then
					notify(profile.userId, "THE WAVE IS MOVING", "warn")
				end
			end
		end
		return
	end

	if hazard.phase == "sweeping" then
		local distance = GameConfig.Hazard.endZ - GameConfig.Hazard.startZ
		local progress = math.clamp((now - hazard.startedAt) / GameConfig.Hazard.travelSeconds, 0, 1)
		hazard.z = GameConfig.Hazard.startZ + distance * progress
		setWaveZ(hazard.z)
		damageCaughtPlayers()
		if progress >= 1 then
			hazard.phase = "cooldown"
			hazard.startedAt = now
			hazard.nextAt = now + GameConfig.Hazard.interval
			setWaveVisible(false)
			for _, profile in ipairs(Store.allPlayers()) do
				if notify then
					notify(profile.userId, "Wave passed. Income x2 while you sit at your base!", "good")
				end
			end
		end
		return
	end

	if hazard.phase == "cooldown" then
		if now >= hazard.nextAt then
			Events.startHazard()
		end
	end
end

function Events.hazardPhase(): string
	return Store.state.hazard.phase
end

function Events.hazardZ(): number
	return Store.state.hazard.z
end

function Events.hazardSecondsLeft(): number
	local hazard = Store.state.hazard
	if hazard.phase == "warning" then
		return math.max(0, GameConfig.Hazard.warningSeconds - (os.clock() - hazard.startedAt))
	elseif hazard.phase == "sweeping" then
		return math.max(0, GameConfig.Hazard.travelSeconds - (os.clock() - hazard.startedAt))
	end
	return 0
end

function Events.incomeBoost(profile): number
	local hazard = Store.state.hazard
	if hazard.phase == "cooldown" then
		return GameConfig.Hazard.incomeBoost
	end
	if hazard.phase == "sweeping" then
		local position = PlayerService.positionFor(profile.userId)
		if position and PlayerService.isSafeAtBase(profile, position) then
			return GameConfig.Hazard.incomeBoost
		end
	end
	return 1
end

function Events.ensureRivals()
	for _, plotIndex in ipairs(PlotLayout.RivalPlotIndexes) do
		local exists = false
		for _, rival in pairs(Store.state.rivals) do
			if rival.plotIndex == plotIndex then
				exists = true
			end
		end
		if not exists then
			local nameIndex = table.find(PlotLayout.RivalPlotIndexes, plotIndex) or 1
			local rivalName = GameConfig.Rival.names[((nameIndex - 1) % #GameConfig.Rival.names) + 1]
			local rival = Store.newRival(plotIndex, rivalName)
			Store.state.rivals[plotIndex] = rival
			for slotIndex = 1, GameConfig.Rival.maxSlots do
				local def = BrainrotDefs.randomDef()
				rival.slots[slotIndex] = {
					defId = def.id,
					mutationId = BrainrotDefs.rollMutation(),
					rate = def.rate,
				}
			end
			Bases.syncRival(rival)
		end
	end
end

function Events.stepRivals(dt: number)
	local now = os.clock()
	for _, rival in pairs(Store.state.rivals) do
		if now >= rival.nextRestock then
			rival.nextRestock = now + GameConfig.Rival.restockInterval
			local slotIndex = math.random(1, GameConfig.Rival.maxSlots)
			local def = BrainrotDefs.randomDef()
			rival.slots[slotIndex] = {
				defId = def.id,
				mutationId = BrainrotDefs.rollMutation(),
				rate = def.rate,
			}
			Bases.syncRival(rival)
		end
	end
end

return Events
