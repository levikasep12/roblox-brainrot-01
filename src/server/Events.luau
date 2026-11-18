-- Events: the hazard. A wall of energy sweeps the map on a timer. The cycle is
-- idle -> warning (countdown) -> sweeping (wall travels) -> passed (x2 income
-- window). Hazards force players home: anyone caught outside their own plot
-- radius when the wave arrives loses a cut of their money.
--
-- The module publishes its phase to clients through HazardUpdated; the client's
-- banner is the single notice for a passed wave (see HudController), which is
-- why this module never also asks Economy to toast "wave passed".

local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Events = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local Store
local Bases
local Net
local Roster

local phase = "idle"
local phaseEndsAt = 0
local wall: Part? = nil

function Events.init(deps: any)
	Store = deps.store
	Bases = deps.bases
	Net = deps.net
	Roster = deps.roster
end

function Events.getState()
	local now = now()
	return {
		phase = phase,
		left = math.max(0, phaseEndsAt - now),
		x2Left = math.max(0, (Events.x2Until or 0) - now),
	}
end

function Events.x2Active(): boolean
	return now() < (Events.x2Until or 0)
end

local function pushState()
	local remote = Net.get("HazardUpdated")
	if remote then
		local state = Events.getState()
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			remote:FireClient(player, state)
		end
	end
end

local function beginWarning()
	phase = "warning"
	phaseEndsAt = now() + Config.WaveWarning
	Roster.broadcast()
end

local function buildWall(): Part
	local wallPart = Instance.new("Part")
	wallPart.Name = "HazardWaveWall"
	wallPart.Size = Vector3.new(4, 42, 340)
	wallPart.Position = Vector3.new(Config.WaveWallStartX, 20, 0)
	wallPart.Anchored = true
	wallPart.CanCollide = false
	wallPart.CanQuery = false
	wallPart.CanTouch = false
	wallPart.Material = Enum.Material.ForceField
	wallPart.Color = Color3.fromRGB(255, 92, 132)
	wallPart.Transparency = 0.25
	wallPart.Parent = workspace

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 92, 132)
	light.Range = 60
	light.Brightness = 3
	light.Parent = wallPart
	return wallPart
end

local function punishStragglers()
	for player, profile in pairs(Store.all()) do
		if not Bases.isHome(player) then
			local cut = math.floor(profile.money * 0.12)
			profile.money = math.max(0, profile.money - cut)
			if cut > 0 then
				local remote = Net.get("Notice")
				if remote then
					remote:FireClient(player, ("Caught by the wave! Lost $%d."):format(cut))
				end
			end
		end
	end
end

local function beginSweep()
	phase = "sweeping"
	phaseEndsAt = now() + Config.WaveSweep
	wall = buildWall()
	punishStragglers()
	Roster.broadcast()
end

local function beginPassed()
	phase = "passed"
	Events.x2Until = now() + Config.WaveX2Duration
	phaseEndsAt = now() + Config.WaveX2Duration
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local profile = Store.get(player)
		if profile then
			profile.x2Until = Events.x2Until
		end
	end
	if wall then
		wall:Destroy()
		wall = nil
	end
	Roster.broadcast()
end

function Events.start()
	phase = "idle"
	phaseEndsAt = now() + Config.WaveIdle

	-- Phase driver: advances the cycle when its timer runs out.
	RunService.Heartbeat:Connect(function()
		local now = now()
		if now < phaseEndsAt then
			return
		end
		if phase == "idle" then
			beginWarning()
		elseif phase == "warning" then
			beginSweep()
		elseif phase == "sweeping" then
			beginPassed()
		else
			phase = "idle"
			phaseEndsAt = now + Config.WaveCooldown
		end
	end)

	-- Wall travel: slides across the map during the sweep, posting pushes.
	RunService.Heartbeat:Connect(function(dt)
		if phase ~= "sweeping" or not wall then
			return
		end
		local elapsed = Config.WaveSweep - math.max(0, phaseEndsAt - now())
		local t = math.clamp(elapsed / Config.WaveSweep, 0, 1)
		local x = Config.WaveWallStartX + (Config.WaveWallEndX - Config.WaveWallStartX) * t
		wall.Position = Vector3.new(x, 20, 0)
		wall.Transparency = 0.25 + math.sin(now() * 8) * 0.08
	end)

	-- Banner text pushed once per second (the countdown needs it); the client
	-- turns phases into banner styling.
	task.spawn(function()
		while true do
			task.wait(0.5)
			pushState()
		end
	end)
end

Events.pushState = pushState

return Events
