-- Client entrypoint. Renders the HUD from the server's state snapshot, wires the
-- buttons and keys, and asks the server for every action (it never changes state).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Feedback = require(ReplicatedStorage.Shared.Feedback)

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hud = HUD.create(player)
hud.displayedMoney = 0

local stateSync = Remotes.get("StateSync")
local showToast = Remotes.get("ShowToast")
local celebrate = Remotes.get("Celebrate")
local buyRemote = Remotes.get("BuyBrainrot")
local rebirthRemote = Remotes.get("Rebirth")
local lockRemote = Remotes.get("ToggleLock")
local buyResult = Remotes.get("BuyResult")

local latestState = nil
local hudBuiltShop = false

-- The banner follows the wave phase:
--   warning  -> stays up (gameplay-critical)
--   sweeping -> stays up (gameplay-critical)
--   double   -> shown once for 2.5s only; the x2 badge carries the state afterwards
--   calm     -> hidden
local lastWavePhase = "calm"

local function renderBanner(state)
	local wave = state.wave
	local phase = wave.phase
	if phase == "warning" then
		HUD.setBanner(hud, string.format("HAZARD WAVE IN %ds - GET HOME", wave.secondsLeft), Color3.fromRGB(255, 196, 80), true)
	elseif phase == "sweeping" then
		HUD.setBanner(hud, "WAVE SWEEPING - DASH HOME NOW", Color3.fromRGB(255, 92, 108), true)
	elseif phase == "double" then
		if lastWavePhase ~= "double" then
			HUD.setBanner(hud, "WAVE PASSED - INCOME x2", Color3.fromRGB(140, 232, 160), false)
		end
	else
		HUD.setBanner(hud, nil)
	end
	lastWavePhase = phase
end

local function applyState(state)
	latestState = state
	HUD.setMoney(hud, state.money)
	HUD.setIncome(hud, state.income, state.multiplier, state.rebirths, state.incomeDouble)
	renderBanner(state)

	if state.plot then
		local lockText = state.plot.lockedSeconds > 0
			and string.format("LOCKED %ds", state.plot.lockedSeconds)
			or string.format("LOCK BASE $%d", Config.Economy.lockCost)
		hud.lockButton.Text = lockText
		if state.plot.lockedSeconds > 0 then
			hud.lockButton.BackgroundColor3 = Color3.fromRGB(70, 110, 160)
		else
			hud.lockButton.BackgroundColor3 = Color3.fromRGB(112, 196, 255)
		end
	end
	if state.rebirthCost then
		hud.rebirthButton.Text = string.format("REBIRTH $%d [R]", state.rebirthCost)
	end

	if state.shop and not hudBuiltShop then
		hudBuiltShop = true
		HUD.buildShop(hud, state.shop)
		local list = hud.shopList
		for _, def in ipairs(state.shop) do
			local row = list:FindFirstChild(def.id)
			local buy = row and row:FindFirstChild("Buy_" .. def.id)
			if buy then
				buy.Activated:Connect(function()
					buyRemote:FireServer(def.id)
				end)
			end
		end
	end
end

stateSync.OnClientEvent:Connect(applyState)

showToast.OnClientEvent:Connect(function(payload)
	HUD.addToast(hud, payload.text, payload.tone)
end)

celebrate.OnClientEvent:Connect(function(payload)
	Feedback.play(payload.kind, nil)
	HUD.addToast(hud, payload.text, "celebrate")
end)

buyResult.OnClientEvent:Connect(function(payload)
	if payload.ok then
		Feedback.play("buy", nil)
	else
		HUD.addToast(hud, payload.message, "danger")
	end
end)

-- Shop open/close.
local shopOpen = false
local function setShopOpen(open)
	shopOpen = open
	hud.shop.Visible = open
end
hud.shopButton.Activated:Connect(function()
	setShopOpen(not shopOpen)
end)
hud.closeShop.Activated:Connect(function()
	setShopOpen(false)
end)

hud.rebirthButton.Activated:Connect(function()
	rebirthRemote:FireServer()
end)
hud.lockButton.Activated:Connect(function()
	lockRemote:FireServer()
end)

-- Keys bound through ContextActionService so the default camera scripts cannot eat
-- them (Roblox's camera eats arrow keys via InputBegan with gameProcessedEvent).
local function onAction(actionName)
	if actionName == "BrainrotRebirth" then
		rebirthRemote:FireServer()
	elseif actionName == "BrainrotLock" then
		lockRemote:FireServer()
	elseif actionName == "BrainrotShop" then
		setShopOpen(not shopOpen)
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("BrainrotRebirth", onAction, false, Config.Keys.rebirth)
ContextActionService:BindAction("BrainrotLock", onAction, false, Config.Keys.lock)
ContextActionService:BindAction("BrainrotShop", onAction, false, Config.Keys.buy)

-- Highlight the nearest runway brainrot so the grab target reads clearly in 3D.
local highlight = Instance.new("Highlight")
highlight.Name = "RunwayHighlight"
highlight.FillColor = Color3.fromRGB(255, 224, 120)
highlight.FillTransparency = 0.75
highlight.OutlineColor = Color3.fromRGB(255, 236, 160)
highlight.DepthMode = Enum.HighlightDepthMode.Occluded

local function updateHighlight()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local arena = workspace:FindFirstChild("Arena")
	if not root or not arena then
		highlight.Adornee = nil
		return
	end
	local best, bestDistance = nil, Config.Conveyor.buyDistance
	for _, model in ipairs(arena:GetChildren()) do
		if model:IsA("Model") and model.Name:sub(1, 7) == "Runway_" then
			local body = model.PrimaryPart
			if body then
				local distance = (body.Position - root.Position).Magnitude
				if distance < bestDistance then
					best, bestDistance = model, distance
				end
			end
		end
	end
	highlight.Adornee = best
end

task.spawn(function()
	while true do
		task.wait(0.2)
		updateHighlight()
	end
end)

player.CharacterAdded:Connect(function()
	task.delay(0.5, function()
		hud.displayedMoney = 0
	end)
end)
