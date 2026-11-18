-- Client entry: builds the HUD and shop, keeps the third-person camera, binds
-- keys, hangs click prompts on belt brainrots and base brainrots, and turns
-- server snapshots into the visible money tick, toasts and particle bursts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local BrainrotDefs = require(Shared.BrainrotDefs)
local Format = require(Shared.Format)
local WorldRefs = require(Shared.WorldRefs)

local Hud = require(script.Parent.Hud)
local ShopUi = require(script.Parent.ShopUi)
local CameraRig = require(script.Parent.CameraRig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local snapshotRemote = remotes:WaitForChild("StateSnapshot")
local notifyRemote = remotes:WaitForChild("Notify")
local burstRemote = remotes:WaitForChild("Burst")

local widgets = Hud.build(playerGui)
local hudGui = playerGui:WaitForChild("BrainrotHud")
local shop = ShopUi.build(hudGui)

local buyFromShop = remotes:WaitForChild("BuyFromShop")
local buyFromConveyor = remotes:WaitForChild("BuyFromConveyor")
local buyLock = remotes:WaitForChild("BuyLock")
local requestRebirth = remotes:WaitForChild("RequestRebirth")
local requestDash = remotes:WaitForChild("RequestDash")
local stealRequest = remotes:WaitForChild("StealRequest")
local sellRequest = remotes:WaitForChild("SellSlot")

CameraRig.start()

local latest = {
	money = 0,
	income = 0,
	multiplier = 1,
	slots = 0,
	plotIndex = 0,
	lockRemaining = 0,
	stealReady = 0,
	dashReady = 0,
	dashing = false,
	hazardPhase = "idle",
	hazardSeconds = 0,
	rebirthCost = 0,
	rebirths = 0,
	lockCost = GameConfig.Lock.cost,
}

local promptsByInstance: { [Instance]: ProximityPrompt } = {}

-- Sound: built-in Roblox SoundService assets only (no uploaded ids).
local function playSound(kind: string)
	local sound = Instance.new("Sound")
	if kind == "buy" then
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.Volume = 0.5
	elseif kind == "steal" then
		sound.SoundId = "rbxasset://sounds/impact_water.mp3"
		sound.Volume = 0.45
	elseif kind == "warn" then
		sound.SoundId = "rbxasset://sounds/uuhhh.mp3"
		sound.Volume = 0.5
	elseif kind == "rebirth" then
		sound.SoundId = "rbxasset://sounds/action_get_up.mp3"
		sound.Volume = 0.5
	else
		sound.SoundId = "rbxasset://sounds/clickfast.wav"
		sound.Volume = 0.35
	end
	sound.PlaybackSpeed = if kind == "buy" then 1.1 elseif kind == "warn" then 0.8 else 1
	sound.Parent = SoundService
	sound:Play()
	task.delay(3, function()
		sound:Destroy()
	end)
end

local function burst(position: Vector3, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Name = "BurstAnchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = Workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 1.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.5, 1.1)
	emitter.Speed = NumberRange.new(8, 18)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -22, 0)
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(28)

	task.delay(1.6, function()
		anchor:Destroy()
	end)
end

local function removePrompt(instance: Instance)
	local prompt = promptsByInstance[instance]
	if prompt then
		prompt:Destroy()
		promptsByInstance[instance] = nil
	end
end

local function attachPrompt(instance: Model, promptKey: string, actionText: string, objectText: string, holdDuration: number, callback: () -> ())
	local existing = promptsByInstance[instance]
	if existing then
		return
	end
	local primary = nil
	local bestVolume = 0
	for _, part in ipairs(instance:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Root" and part.Transparency < 0.9 then
			local volume = part.Size.X * part.Size.Y * part.Size.Z
			if volume > bestVolume then
				bestVolume = volume
				primary = part
			end
		end
	end
	if not primary then
		primary = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
	end
	if not primary then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BrainrotPrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = holdDuration
	prompt.MaxActivationDistance = 22
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = primary
	prompt:SetAttribute("PromptKey", promptKey)
	prompt.Triggered:Connect(function()
		callback()
	end)
	promptsByInstance[instance] = prompt
end

local function refreshBeltPrompts()
	local folder = WorldRefs.beltBrainrots()
	if not folder then
		return
	end
	local live = {}
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("BeltId") then
			live[model] = true
			local defId = model:GetAttribute("DefId")
			local mutationId = model:GetAttribute("MutationId")
			local def = defId and BrainrotDefs.get(defId)
			if def and not promptsByInstance[model] then
				local price = BrainrotDefs.priceFor(def, mutationId or "Normal")
				local label = BrainrotDefs.displayName(def, mutationId or "Normal")
				attachPrompt(model, "belt", "BUY  " .. Format.money(price), label, 0.15, function()
					buyFromConveyor:FireServer(model:GetAttribute("BeltId"))
				end)
			end
		end
	end
	for instance in pairs(promptsByInstance) do
		if instance:IsA("Model") and instance:GetAttribute("BeltId") and not live[instance] then
			removePrompt(instance)
		end
	end
end

local function refreshBasePrompts()
	local plots = WorldRefs.plots()
	if not plots then
		return
	end
	for _, plotModel in ipairs(plots:GetChildren()) do
		local plotIndex = plotModel:GetAttribute("PlotIndex")
		local brainrotFolder = plotModel:FindFirstChild("Brainrots")
		if brainrotFolder then
			for _, model in ipairs(brainrotFolder:GetChildren()) do
				if model:IsA("Model") and model:GetAttribute("SlotIndex") then
					local defId = model:GetAttribute("DefId")
					local mutationId = model:GetAttribute("MutationId") or "Normal"
					local def = defId and BrainrotDefs.get(defId)
					local isMine = plotIndex == latest.plotIndex
					local wantKey = if isMine then "own" else "steal"
					local existing = promptsByInstance[model]
					if existing and existing:GetAttribute("PromptKey") ~= wantKey then
						removePrompt(model)
						existing = nil
					end
					if def and not existing then
						if isMine then
							local sellPrice = math.floor(BrainrotDefs.priceFor(def, mutationId) * 0.45)
							attachPrompt(model, "own", "SELL  " .. Format.money(sellPrice), def.name, 0.35, function()
								sellRequest:FireServer(plotIndex, model:GetAttribute("SlotIndex"))
							end)
						else
							attachPrompt(model, "steal", "STEAL", def.name, 0.75, function()
								stealRequest:FireServer(plotIndex, model:GetAttribute("SlotIndex"))
							end)
						end
					end
				end
			end
		end
	end
end

local promptClock = 0
RunService.Heartbeat:Connect(function(dt)
	promptClock += dt
	if promptClock >= 0.6 then
		promptClock = 0
		for instance, prompt in pairs(promptsByInstance) do
			if not instance.Parent or not prompt.Parent then
				prompt:Destroy()
				promptsByInstance[instance] = nil
			end
		end
		refreshBeltPrompts()
		refreshBasePrompts()
	end
end)

local function findNearestStealTarget(): (number?, number?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil, nil
	end
	local plots = WorldRefs.plots()
	if not plots then
		return nil, nil
	end
	local bestPlot, bestSlot = nil, nil
	local bestDistance = GameConfig.Steal.range
	for _, plotModel in ipairs(plots:GetChildren()) do
		local plotIndex = plotModel:GetAttribute("PlotIndex")
		if plotIndex and plotIndex ~= latest.plotIndex then
			local brainrotFolder = plotModel:FindFirstChild("Brainrots")
			if brainrotFolder then
				for _, model in ipairs(brainrotFolder:GetChildren()) do
					if model:IsA("Model") and model.PrimaryPart then
						local distance = (model.PrimaryPart.Position - root.Position).Magnitude
						if distance <= bestDistance then
							bestDistance = distance
							bestPlot = plotIndex
							bestSlot = model:GetAttribute("SlotIndex")
						end
					end
				end
			end
		end
	end
	return bestPlot, bestSlot
end

local function pressSteal()
	local plotIndex, slotIndex = findNearestStealTarget()
	if plotIndex and slotIndex then
		stealRequest:FireServer(plotIndex, slotIndex)
	else
		Hud.toast("No brainrot in reach - get closer to a rival base", "info")
	end
end

local function pressLock()
	buyLock:FireServer()
end

local function pressRebirth()
	requestRebirth:FireServer()
end

local function pressDash()
	requestDash:FireServer()
end

local function pressShop()
	shop.toggle()
end

ContextActionService:BindAction("StealNearest", function(_, state)
	if state == Enum.UserInputState.Begin then
		pressSteal()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.F)

ContextActionService:BindAction("LockBase", function(_, state)
	if state == Enum.UserInputState.Begin then
		pressLock()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.L)

ContextActionService:BindAction("Rebirth", function(_, state)
	if state == Enum.UserInputState.Begin then
		pressRebirth()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.R)

ContextActionService:BindAction("DashHome", function(_, state)
	if state == Enum.UserInputState.Begin then
		pressDash()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.Q)

ContextActionService:BindAction("ToggleShop", function(_, state)
	if state == Enum.UserInputState.Begin then
		pressShop()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.B)

widgets.lock.Activated:Connect(pressLock)
widgets.steal.Activated:Connect(pressSteal)
widgets.dash.Activated:Connect(pressDash)
widgets.rebirth.Activated:Connect(pressRebirth)
ShopUi.setBuyHandler(function(defId)
	buyFromShop:FireServer(defId)
end)

notifyRemote.OnClientEvent:Connect(function(message: string, tone: string)
	Hud.toast(message, tone)
	if tone == "bad" then
		playSound("warn")
	elseif tone == "good" then
		playSound("buy")
	elseif tone == "info" then
		playSound("click")
	end
end)

burstRemote.OnClientEvent:Connect(function(position: Vector3, color: Color3)
	burst(position, color)
	playSound("buy")
end)

local shopRenderClock = 0
snapshotRemote.OnClientEvent:Connect(function(payload)
	local profile = payload.profile
	latest.money = profile.money
	latest.income = profile.income
	latest.multiplier = profile.multiplier
	latest.plotIndex = profile.plotIndex
	latest.lockRemaining = profile.lockRemaining
	latest.stealReady = profile.stealReady
	latest.dashReady = profile.dashReady
	latest.dashing = profile.dashing
	latest.rebirths = profile.rebirths
	latest.rebirthCost = payload.rebirthCost
	latest.lockCost = payload.lockCost
	latest.hazardPhase = payload.hazard.phase
	latest.hazardSeconds = payload.hazard.secondsLeft

	local slotCount = 0
	for slot = 1, GameConfig.StartingSlots do
		if profile.slots[slot] then
			slotCount += 1
		end
	end
	latest.slots = slotCount

	Hud.setMoney(profile.money)
	Hud.setIncome(profile.income)
	Hud.setMultiplier(profile.multiplier)
	Hud.setBase(profile.plotIndex, slotCount)
	Hud.setLock(profile.lockRemaining > 0, profile.lockRemaining, payload.lockCost)
	Hud.setSteal(profile.stealReady <= 0, profile.stealReady)
	Hud.setDash(profile.dashing, profile.dashReady)
	Hud.setHazard(payload.hazard.phase, payload.hazard.secondsLeft)

	local canAfford = profile.money >= payload.rebirthCost
	local maxed = profile.rebirths >= GameConfig.Rebirth.maxRebirths
	Hud.setRebirth(profile.rebirths, payload.rebirthCost, profile.multiplier, canAfford, maxed)

	shopRenderClock += 1
	if shop.isOpen() or shopRenderClock % 5 == 0 then
		ShopUi.render(payload.shop, profile.money)
	end
end)

player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = 22
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
	end
end)

Hud.toast("Welcome! Walk to the belt and press E to buy a brainrot", "info")
