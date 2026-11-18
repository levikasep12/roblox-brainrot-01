-- The hazard: every minute or so a neon wave sweeps the map from the altar
-- end to the spawn end. A warning goes out first; when the wave reaches a
-- player standing away from their base it knocks them toward home, takes a
-- slice of their money and flashes their screen red. Standing on your own
-- base is safe, so the event teaches "dash home".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Store = require(script.Parent.Store)

local Events = {}

local WAVE_START_Z = Config.AltarPosition.Z - 30
local WAVE_END_Z = Config.ShopPosition.Z + 30

Events.WaveRemote = nil

local function buildWaveWall()
	local wall = Instance.new("Part")
	wall.Name = "HazardWave"
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanQuery = false
	wall.CanTouch = false
	wall.Size = Vector3.new(300, 26, 8)
	wall.Color = Color3.fromRGB(255, 70, 120)
	wall.Material = Enum.Material.ForceField
	wall.Transparency = 0.25
	wall.Position = Vector3.new(0, 12, WAVE_START_Z)
	wall.Parent = workspace
	return wall
end

local function announce(text, duration)
	for _, player in ipairs(Players:GetPlayers()) do
		local record = Store.GetPlayer(player.UserId)
		if record then
			Events.WaveRemote:FireClient(player, {
				text = text,
				duration = duration,
			})
		end
	end
end

local function pushPlayerHome(player)
	local character = player.Character
	local record = Store.GetPlayer(player.UserId)
	if not character or not record then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local baseCenter = Config.PlotCenter(record.plotIndex)
	local target = baseCenter + Vector3.new(0, 6, 0)
	local direction = (target - root.Position).Unit
	root.AssemblyLinearVelocity = direction * 120 + Vector3.new(0, 55, 0)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(Config.WaveDamage)
	end
	local moneyLost = math.floor(record.money * Config.WaveMoneyLoss)
	record.money = math.max(0, record.money - moneyLost)
	return moneyLost
end

-- One full wave: warning, sweep, damage window. Called on a loop.
local function runWave(index)
	Store.Wave.active = true
	Store.Wave.index = index
	Store.Wave.warning = Config.WaveWarningTime
	announce("HAZARD WAVE INCOMING - DASH TO YOUR BASE!", Config.WaveWarningTime)

	local elapsed = 0
	while elapsed < Config.WaveWarningTime do
		task.wait(0.2)
		elapsed += 0.2
		Store.Wave.warning = math.max(0, Config.WaveWarningTime - elapsed)
	end
	Store.Wave.warning = 0

	local wall = buildWaveWall()
	local travel = Config.WaveTravelTime
	local startClock = os.clock()
	local hitThisPass = {}
	local mood = Instance.new("ColorCorrectionEffect")
	mood.Name = "HazardMood"
	mood.TintColor = Color3.fromRGB(255, 214, 224)
	mood.Saturation = 0.15
	mood.Parent = game:GetService("Lighting")

	while true do
		local alpha = math.clamp((os.clock() - startClock) / travel, 0, 1)
		local z = WAVE_START_Z + (WAVE_END_Z - WAVE_START_Z) * alpha
		wall.Position = Vector3.new(0, 12, z)
		wall.Transparency = 0.25 + math.sin(os.clock() * 12) * 0.08

		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local record = Store.GetPlayer(player.UserId)
			if character and record and not hitThisPass[player.UserId] then
				local root = character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.Z - z) < 10 then
					hitThisPass[player.UserId] = true
					local onOwnBase = Config.IsInsidePlot(root.Position, record.plotIndex)
					if not onOwnBase then
						local lost = pushPlayerHome(player)
						if lost and lost > 0 then
							announce("The wave hit you: -$" .. lost .. " and sent you home", 3)
						else
							announce("The wave hit you - get back to your base", 3)
						end
					else
						announce("Your base shielded you from the wave", 2.5)
					end
				end
			end
		end

		if alpha >= 1 then
			break
		end
		task.wait(0.06)
	end

	local fade = TweenService:Create(wall, TweenInfo.new(0.6), { Transparency = 1 })
	fade:Play()
	task.wait(0.7)
	wall:Destroy()
	mood:Destroy()
	Store.Wave.active = false
	Store.Wave.index = 0
end

function Events.Start(waveRemote)
	Events.WaveRemote = waveRemote
	task.spawn(function()
		task.wait(Config.WaveFirstDelay)
		local index = 0
		while true do
			index += 1
			runWave(index)
			local gap = Config.WaveIntervalMin + math.random() * (Config.WaveIntervalMax - Config.WaveIntervalMin)
			task.wait(gap)
		end
	end)
end

return Events
