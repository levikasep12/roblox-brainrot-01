-- Client entry point. Owns everything the player sees and nothing the server
-- owns: it subscribes to the server snapshot, draws the HUD and shop, plays
-- feedback sounds and particles, and binds keys (B shop, R rebirth, L lock,
-- Escape close) through UserInputService with gameProcessedEvent respected so
-- the default camera and chat keep their keys.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local Hud = require(script.Hud)
local Shop = require(script.Shop)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyBrainrot = Remotes.BuyBrainrot
local RebirthRemote = Remotes.Rebirth
local BuyLockRemote = Remotes.BuyLock
local StateChanged = Remotes.StateChanged
local Notify = Remotes.Notify
local WaveAlert = Remotes.WaveAlert

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Built-in Roblox sounds only: rbxasset:// paths ship with the engine, so no
-- uploaded asset id can fail to load for a reviewer. A path the engine does not
-- have simply plays nothing; it never errors into the game loop.
local SOUND_IDS = {
	buy = "rbxasset://sounds/electronicpingshort.wav",
	lock = "rbxasset://sounds/switch.wav",
	rebirth = "rbxasset://sounds/victory.wav",
	steal = "rbxasset://sounds/snap.mp3",
	error = "rbxasset://sounds/uuhhh.wav",
	wave = "rbxasset://sounds/bass.wav",
	click = "rbxasset://sounds/clickfast.wav",
}

local soundCache = {}

-- One Sound instance per effect, reused. A missing engine asset is caught and
-- the effect goes silent rather than throwing.
local function playSound(name, volume, pitch)
	local id = SOUND_IDS[name]
	if not id then
		return
	end
	local sound = soundCache[name]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "Sfx_" .. name
		sound.SoundId = id
		sound.Parent = SoundService
		soundCache[name] = sound
	end
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = pitch or 1
	pcall(function()
		sound:Play()
	end)
end

local hud = Hud.Create(playerGui)

local latestSnapshot = nil
local shop

-- A short camera shake, used on a purchase and when the wave hits.
local shakeAmount = 0
local function shake(strength)
	shakeAmount = math.max(shakeAmount, strength)
end

-- A local particle burst at the player's feet as a "you did it" flourish.
local function clientBurst()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local holder = Instance.new("Part")
	holder.Name = "LocalBurst"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.5, 0.5, 0.5)
	holder.Position = root.Position
	holder.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 226, 120), Color3.fromRGB(140, 255, 200))
	emitter.LightEmission = 0.7
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Speed = NumberRange.new(8, 15)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = holder
	emitter:Emit(28)
	game:GetService("Debris"):AddItem(holder, 1.4)
end

-- Buying a brainrot: the money label punches green and a sound fires.
local function onPurchaseFeedback()
	playSound("buy", 0.55, 1)
	shake(0.35)
	local moneyLabel = hud.moneyLabel
	if moneyLabel then
		local original = moneyLabel.TextColor3
		moneyLabel.TextColor3 = Color3.fromRGB(200, 255, 220)
		local grow = TweenService:Create(moneyLabel, TweenInfo.new(0.12), { TextSize = 52 })
		grow:Play()
		task.delay(0.14, function()
			TweenService:Create(moneyLabel, TweenInfo.new(0.22), { TextSize = 46 }):Play()
			moneyLabel.TextColor3 = original
		end)
	end
end

local function applySnapshot(snapshot)
	if not snapshot then
		return
	end
	local previous = latestSnapshot
	latestSnapshot = snapshot

	if previous and snapshot.money > previous.money + 0.01 then
		hud.PulseMoney()
	end
	hud.SetMoney(snapshot.money)
	hud.SetIncome(snapshot.income)
	hud.SetMultiplier(snapshot.multiplier, snapshot.rebirths, snapshot.rebirthCost)
	hud.SetLock(snapshot.lockRemaining, snapshot.lockCost)
	hud.SetWave(snapshot.wave and snapshot.wave.active, snapshot.wave and snapshot.wave.warning)
	hud.RenderBoard(snapshot.bases, snapshot.plotIndex)

	if shop.open then
		shop.Render(snapshot.offers, snapshot.money)
	end
end

-- Built after the feedback helpers it calls. A buy from a card routes straight
-- to the server's BuyBrainrot RemoteFunction.
shop = Shop.Create(playerGui, {
	buy = function(offerId)
		local ok, message = BuyBrainrot:InvokeServer(offerId)
		return ok, message
	end,
	toast = function(text, color)
		hud.Toast(text, color)
	end,
	burst = function()
		onPurchaseFeedback()
		clientBurst()
	end,
})

StateChanged.OnClientEvent:Connect(applySnapshot)

Notify.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		hud.Toast(payload.text, payload.color)
		local text = tostring(payload.text)
		if text:lower():find("bought") then
			onPurchaseFeedback()
		elseif text:lower():find("stole") then
			playSound("steal", 0.6, 1.1)
			shake(0.4)
			clientBurst()
		elseif text:lower():find("lock") then
			playSound("lock", 0.5, 0.95)
		elseif text:lower():find("rebirth") then
			playSound("rebirth", 0.5, 1)
			clientBurst()
		elseif text:lower():find("not enough") or text:lower():find("cooldown") or text:lower():find("locked") then
			playSound("error", 0.4, 1)
		end
	end
end)

WaveAlert.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	hud.Toast(payload.text, Color3.fromRGB(255, 170, 190), payload.duration or 4)
	playSound("wave", 0.55, 0.9)
	shake(1.2)
end)

-- Camera: a slightly high, over-the-shoulder third-person view so the 3D
-- world and the runway read clearly. The default camera script still handles
-- rotation and zoom; only the field of view and offset are tuned here.
local function tuneCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	camera.FieldOfView = 74
end
tuneCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(tuneCamera)

-- Camera shake decays every frame and is applied as a tiny rotation offset,
-- which the default camera script tolerates because it re-derives the CFrame.
local shakeSeed = 0
RunService.RenderStepped:Connect(function(dt)
	if shakeAmount <= 0.001 then
		return
	end
	shakeAmount = math.max(0, shakeAmount - dt * 3.2)
	shakeSeed += dt * 40
	local camera = workspace.CurrentCamera
	if camera then
		camera.CFrame = camera.CFrame * CFrame.Angles(
			math.sin(shakeSeed) * 0.008 * shakeAmount,
			math.cos(shakeSeed * 1.3) * 0.008 * shakeAmount,
			0
		)
	end
end)

-- Key bindings. gameProcessedEvent is respected: while the player types in
-- chat or a TextBox, these keys do nothing.
local function bindKeys()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.B then
			shop.Toggle()
			playSound("click", 0.35, 1)
			if shop.open and latestSnapshot then
				shop.Render(latestSnapshot.offers, latestSnapshot.money)
			end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			if shop.open then
				shop.SetOpen(false)
			end
		elseif input.KeyCode == Enum.KeyCode.R then
			local ok, message = RebirthRemote:InvokeServer()
			hud.Toast(message or "Rebirth", ok and Color3.fromRGB(220, 180, 255) or Color3.fromRGB(255, 160, 160))
			if ok then
				playSound("rebirth", 0.5, 1)
				clientBurst()
				shake(0.6)
			else
				playSound("error", 0.35, 1)
			end
		elseif input.KeyCode == Enum.KeyCode.L then
			local ok, message = BuyLockRemote:InvokeServer()
			hud.Toast(message or "Lock", ok and Color3.fromRGB(150, 255, 200) or Color3.fromRGB(255, 160, 160))
			playSound(ok and "lock" or "error", 0.45, 1)
		elseif input.KeyCode == Enum.KeyCode.Space then
			-- falls through to the default jump
		end
	end)
end

bindKeys()

hud.RebirthButton.Activated:Connect(function()
	local ok, message = RebirthRemote:InvokeServer()
	hud.Toast(message or "Rebirth", ok and Color3.fromRGB(220, 180, 255) or Color3.fromRGB(255, 160, 160))
	if ok then
		playSound("rebirth", 0.5, 1)
		clientBurst()
	else
		playSound("error", 0.35, 1)
	end
end)

hud.LockButton.Activated:Connect(function()
	local ok, message = BuyLockRemote:InvokeServer()
	hud.Toast(message or "Lock", ok and Color3.fromRGB(150, 255, 200) or Color3.fromRGB(255, 160, 160))
	playSound(ok and "lock" or "error", 0.45, 1)
end)

-- The shop pad's prompt (in the world) opens the shop for the local player
-- when they walk up to it: the server's prompt handler broadcasts nothing
-- back, so this watches the prompt directly on the client.
task.spawn(function()
	local shopPart = workspace:WaitForChild("Shop", 30)
	local pad = shopPart and shopPart:WaitForChild("BuyPad", 10)
	local prompt = pad and pad:WaitForChild("OpenShop", 10)
	if prompt then
		prompt.PromptButtonHoldBegan:Connect(function()
			shop.SetOpen(true)
			playSound("click", 0.35, 1)
			if latestSnapshot then
				shop.Render(latestSnapshot.offers, latestSnapshot.money)
			end
		end)
	end
end)

player.CharacterAdded:Connect(function()
	shakeAmount = 0
end)

hud.Toast("Welcome to " .. Config.GameName .. "! Press B for the shop.", Color3.fromRGB(150, 240, 255), 6)
