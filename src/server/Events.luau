-- The hazard wave: a calm -> warning -> sweeping -> double-income cycle. The sweep
-- is a real wall that crosses the map; anyone not standing on their own plot when it
-- passes loses a share of their money. The x2 income window follows it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Store = require(script.Parent.Store)

local Events = {}

local wall = nil
local wallHit = {}

local function toast(player, text, tone)
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = folder and folder:FindFirstChild("ShowToast")
	if remote then
		remote:FireClient(player, { text = text, tone = tone or "info" })
	end
end

local function isHome(player)
	local record = Store.players[player.UserId]
	if not record or not record.plotIndex then
		return false
	end
	local center = Config.World.plotCenters[record.plotIndex]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not center then
		return false
	end
	local flat = Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z)
	return flat.Magnitude <= Config.World.plotHalfWidth + 6
end

local function makeWall(world)
	local existing = world:FindFirstChild("HazardWall")
	if existing then
		existing:Destroy()
	end
	local part = Instance.new("Part")
	part.Name = "HazardWall"
	part.Size = Vector3.new(4, 70, Config.Wave.wallHalfExtent * 2)
	part.Position = Vector3.new(Config.Wave.wallStartX, 35, 6)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 74, 96)
	part.Transparency = 0.35
	part.Parent = world

	local light = Instance.new("PointLight")
	light.Brightness = 3
	light.Range = 40
	light.Color = Color3.fromRGB(255, 90, 110)
	light.Parent = part
	return part
end

-- The wall sweeps in +X. Anyone it has already passed, who is not standing on their own
-- plot, is caught once and loses a share of their money.
local function punishStragglers()
	for _, player in ipairs(Players:GetPlayers()) do
		local record = Store.players[player.UserId]
		if record and not wallHit[player.UserId] and wall then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root.Position.X < wall.Position.X and not isHome(player) then
				wallHit[player.UserId] = true
				local loss = math.floor(record.money * Config.Economy.wavePenaltyShare)
				record.money = math.max(0, record.money - loss)
				toast(player, string.format("WAVE CAUGHT YOU  -$%d", loss), "danger")
			end
		end
	end
end

local function runSweep()
	Store.wave.phase = "sweeping"
	Store.wave.endsAt = os.clock() + Config.Wave.sweepSeconds
	wallHit = {}
	if not wall then
		return
	end
	wall.CFrame = CFrame.new(Config.Wave.wallStartX, 35, 6)
	local tween = TweenService:Create(
		wall,
		TweenInfo.new(Config.Wave.sweepSeconds, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.new(Config.Wave.wallEndX, 35, 6) }
	)
	tween:Play()

	local elapsed = 0
	while elapsed < Config.Wave.sweepSeconds do
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
		punishStragglers()
	end
	Store.wave.phase = "double"
	Store.wave.doubleUntil = os.clock() + Config.Wave.doubleSeconds
	Store.wave.endsAt = Store.wave.doubleUntil
	if wall then
		wall.Transparency = 1
	end
end

function Events.start(world)
	task.spawn(function()
		wall = makeWall(world)
		wall.Transparency = 1
		Store.wave.phase = "calm"
		Store.wave.endsAt = os.clock() + Config.Wave.firstCalmSeconds
		task.wait(Config.Wave.firstCalmSeconds)

		while true do
			Store.wave.waveNumber += 1
			Store.wave.phase = "warning"
			Store.wave.endsAt = os.clock() + Config.Wave.warningSeconds
			task.wait(Config.Wave.warningSeconds)

			if wall then
				wall.Transparency = 0.35
			end
			runSweep()

			-- The x2 window is the "double" phase; runSweep already set its end time.
			task.wait(Config.Wave.doubleSeconds)
			Store.wave.phase = "calm"
			Store.wave.doubleUntil = 0
			Store.wave.endsAt = os.clock() + Config.Wave.calmSeconds
			if wall then
				wall.Transparency = 1
			end
			task.wait(Config.Wave.calmSeconds)
		end
	end)
end

return Events
