-- Server entry point. Builds the world, seeds the demo rivals and the
-- conveyor, publishes remotes, then runs the money tick and pushes snapshots.
-- Every prompt and remote lands here and is routed to the module that owns
-- the rule (Economy for money, Steal for theft, Events for the wave).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local BrainrotDefs = require(Shared.BrainrotDefs)

local WorldBuilder = require(script.WorldBuilder)
local Store = require(script.Store)
local Economy = require(script.Economy)
local BaseService = require(script.BaseService)
local Spawner = require(script.Spawner)
local Steal = require(script.Steal)
local Events = require(script.Events)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyBrainrot = Remotes.BuyBrainrot
local RebirthRemote = Remotes.Rebirth
local BuyLockRemote = Remotes.BuyLock
local StateChanged = Remotes.StateChanged
local Notify = Remotes.Notify
local WaveAlert = Remotes.WaveAlert

WorldBuilder.Build()
Store.ResetBases()
BaseService.SeedRivals()
BaseService.StartRivalRestock(14)

-- One publish path so every mutation, prompt and timer sends the same shape.
local function pushState(player)
	if not player.Parent then
		return
	end
	local snapshot = Store.SnapshotFor(player)
	if snapshot then
		StateChanged:FireClient(player, snapshot)
	end
end

local function pushAll()
	for _, player in ipairs(Players:GetPlayers()) do
		pushState(player)
	end
end

local function notify(player, text, color)
	Notify:FireClient(player, {
		text = text,
		color = color or Color3.fromRGB(255, 255, 255),
	})
end

local function claimPlot(player)
	local plotIndex = Store.FindFreePlot()
	if not plotIndex then
		return nil
	end
	-- A plot the rivals stocked loses its props before a real player takes it.
	BaseService.ClearBaseVisuals(plotIndex)
	local record = Store.CreatePlayer(player, plotIndex)
	BaseService.RefreshPlotSign(plotIndex)
	return record
end

-- Rebirth from the altar prompt, the HUD button and the R key all land here so
-- the base, the HUD and the labels cannot drift apart.
local function performRebirth(player)
	local ok, message = Economy.Rebirth(player, function(plotIndex)
		BaseService.ClearBaseVisuals(plotIndex)
	end)
	if ok then
		local record = Store.GetPlayer(player.UserId)
		if record then
			BaseService.RefreshSlotLabels(record.plotIndex, Config.MultiplierFor(record.rebirths))
		end
	end
	notify(player, message, ok and Color3.fromRGB(220, 180, 255) or Color3.fromRGB(255, 150, 150))
	pushState(player)
	pushAll()
	return ok, message
end

local function onPlayerAdded(player)
	local record = claimPlot(player)
	if not record then
		player:Kick("The server is full. Try again in a moment.")
		return
	end

	BaseService.WatchLock(record.plotIndex)
	BaseService.RefreshPlotSign(record.plotIndex)
	notify(player, "Welcome! Buy a brainrot off the conveyor, then defend your base.", Color3.fromRGB(140, 240, 255))

	player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart")
		local base = Config.PlotCenter(record.plotIndex)
		-- Lands on the plot deck, in the gap between the two pad rows.
		root.CFrame = CFrame.new(base + Vector3.new(0, Config.PlotTopY + 4, 0))
	end)

	pushState(player)
	pushAll()
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	local record = Store.GetPlayer(player.UserId)
	Store.RemovePlayer(player)
	if record then
		BaseService.ClearBaseVisuals(record.plotIndex)
		BaseService.RefreshPlotSign(record.plotIndex)
	end
	pushAll()
end)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Income tick: credit money, then push at a gentler rate than the tick so the
-- network is quiet but the HUD still moves several times a second.
local sincePush = 0
RunService.Heartbeat:Connect(function(dt)
	Economy.TickIncome(dt)
	sincePush += dt
	if sincePush >= 0.2 then
		sincePush = 0
		for _, player in ipairs(Players:GetPlayers()) do
			pushState(player)
		end
	end
end)

local function placePurchased(plotIndex, slotIndex, def, mutation, rate, model)
	BaseService.PlaceInSlot(plotIndex, slotIndex, def, mutation, rate, model)
	BaseService.RefreshPlotSign(plotIndex)
end

-- Prompt routing. Every interactable on the map uses a ProximityPrompt with
-- a name this function understands.
local function wirePrompt(prompt)
	local model = prompt:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end
	if prompt.Name == "ClaimBrainrot" then
		prompt.Triggered:Connect(function(player)
			local offerId = model:GetAttribute("OfferId")
			if not offerId then
				return
			end
			local ok, message = Economy.BuyOffer(player, offerId, placePurchased)
			notify(player, message, ok and Color3.fromRGB(140, 255, 170) or Color3.fromRGB(255, 150, 150))
			pushState(player)
			pushAll()
		end)
	elseif prompt.Name == "OpenShop" then
		prompt.Triggered:Connect(function(player)
			notify(player, "Shop opened on your screen. Pick the next tier.", Color3.fromRGB(255, 226, 150))
		end)
	elseif prompt.Name == "RebirthPrompt" then
		prompt.Triggered:Connect(function(player)
			performRebirth(player)
		end)
	elseif prompt.Name == "StealPrompt" then
		prompt.Triggered:Connect(function(player)
			local plotIndex = prompt:GetAttribute("PlotIndex")
			local slotIndex = prompt:GetAttribute("SlotIndex")
			if not plotIndex or not slotIndex then
				return
			end
			local ok, message = Steal.StealSlot(player, plotIndex, slotIndex)
			notify(player, message, ok and Color3.fromRGB(255, 220, 120) or Color3.fromRGB(255, 150, 150))
			pushState(player)
			pushAll()
		end)
	end
end

-- Steal prompts may be created by BaseService.SettleInSlot or here; either way
-- they are wired once, tracked on the prompt itself.
local function attachStealPrompt(model, plotIndex, slotIndex)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local prompt = root:FindFirstChild("StealPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "StealPrompt"
		prompt.ActionText = "Steal"
		prompt.ObjectText = "Take this brainrot"
		prompt.HoldDuration = 1.1
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
	end
	prompt:SetAttribute("PlotIndex", plotIndex)
	prompt:SetAttribute("SlotIndex", slotIndex)
	if not prompt:GetAttribute("Wired") then
		prompt:SetAttribute("Wired", true)
		wirePrompt(prompt)
	end
end

-- Hooks every base brainrot (including the rival seeds) once, then watches for
-- new ones as they are placed or stolen.
local function scanBaseModels()
	for plotIndex = 1, Config.PlotCount do
		local plot = workspace:FindFirstChild("Plot" .. plotIndex)
		if plot then
			for _, model in ipairs(plot:GetChildren()) do
				if model:IsA("Model") and model.Name:match("^Brainrot_") then
					local slotIndex = model:GetAttribute("SlotIndex")
					if slotIndex then
						attachStealPrompt(model, plotIndex, slotIndex)
					end
				end
			end
		end
	end
end

for plotIndex = 1, Config.PlotCount do
	local plot = workspace:WaitForChild("Plot" .. plotIndex)
	plot.ChildAdded:Connect(function(child)
		if child:IsA("Model") and child.Name:match("^Brainrot_") then
			task.wait(0.1)
			local slotIndex = child:GetAttribute("SlotIndex")
			if slotIndex then
				attachStealPrompt(child, plotIndex, slotIndex)
			end
		end
	end)
end
scanBaseModels()

-- A scan on a slow loop keeps prompts correct after a steal re-parents a
-- model without firing ChildAdded on the destination plot's connection.
task.spawn(function()
	while true do
		task.wait(2)
		scanBaseModels()
	end
end)

-- Remotes from the HUD and shop UI.
BuyBrainrot.OnServerInvoke = function(player, offerId)
	if type(offerId) ~= "number" then
		return false, "Bad offer"
	end
	local ok, message = Economy.BuyOffer(player, offerId, function(plotIndex, slotIndex, def, mutation, rate, model)
		BaseService.PlaceInSlot(plotIndex, slotIndex, def, mutation, rate, model)
		BaseService.RefreshPlotSign(plotIndex)
	end)
	pushState(player)
	pushAll()
	return ok, message
end

RebirthRemote.OnServerInvoke = function(player)
	return performRebirth(player)
end

BuyLockRemote.OnServerInvoke = function(player)
	local ok, message = Economy.BuyLock(player)
	if ok then
		BaseService.RefreshPlotSign(Store.GetPlayer(player.UserId).plotIndex)
		BaseService.WatchLock(Store.GetPlayer(player.UserId).plotIndex)
	end
	pushState(player)
	pushAll()
	return ok, message
end

Spawner.Start()
Events.Start(WaveAlert)

print("[Brainrot Rush] server ready: " .. Config.PlotCount .. " plots, " .. #BrainrotDefs.Cast .. " characters")
