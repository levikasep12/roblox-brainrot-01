-- Server entry for Brainrot Rush. Boots the map, connects remotes, runs one
-- heartbeat loop for belt walking, income, hazard and snapshots, and owns
-- every authoritative action a client can request.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.GameConfig)
local BrainrotDefs = require(Shared.BrainrotDefs)
local Format = require(Shared.Format)
local Net = require(Shared.Net)
local WorldBuilder = require(Shared.WorldBuilder)

local Store = require(script.Store)
local Economy = require(script.Economy)
local Bases = require(script.Bases)
local Spawner = require(script.Spawner)
local Steal = require(script.Steal)
local Events = require(script.Events)
local PlayerService = require(script.PlayerService)
local Shop = require(script.Shop)
local ShopShowcase = require(script.ShopShowcase)

local remotes = Net.server()

local function sendNotify(userId: number, message: string, tone: string?)
	remotes.Notify:FireClient(Players:GetPlayerByUserId(userId), message, tone or "info")
end

local function sendBurst(userId: number, position: Vector3, color: Color3)
	remotes.Burst:FireClient(Players:GetPlayerByUserId(userId), position, color)
end

Events.setNotifier(sendNotify, sendBurst)

local function setupLighting()
	local Lighting = game:GetService("Lighting")
	Lighting.Ambient = Color3.fromRGB(84, 88, 104)
	Lighting.OutdoorAmbient = Color3.fromRGB(126, 132, 150)
	Lighting.Brightness = 2.6
	Lighting.ClockTime = 15.4
	Lighting.GeographicLatitude = 12
	Lighting.FogEnd = 640
	Lighting.FogStart = 260
	Lighting.FogColor = Color3.fromRGB(158, 178, 196)
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.GlobalShadows = true

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.32
	atmosphere.Haze = 1.4
	atmosphere.Glare = 0.2
	atmosphere.Color = Color3.fromRGB(204, 216, 230)
	atmosphere.Decay = Color3.fromRGB(140, 158, 182)
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.7
	bloom.Size = 28
	bloom.Threshold = 1.1
	bloom.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Brightness = 0.02
	colorCorrection.Contrast = 0.12
	colorCorrection.Saturation = 0.16
	colorCorrection.Parent = Lighting
end

local function setupMap()
	local oldMap = Workspace:FindFirstChild("BrainrotWorld")
	if oldMap then
		oldMap:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "BrainrotWorld"
	root.Parent = Workspace
	WorldBuilder.build(root)
end

local function pushSnapshot()
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = Store.getPlayer(player.UserId)
		if profile then
			remotes.StateSnapshot:FireClient(player, {
				profile = Store.toSnapshot(profile),
				shop = Shop.catalogFor(profile),
				hazard = {
					phase = Events.hazardPhase(),
					secondsLeft = Events.hazardSecondsLeft(),
					waveIndex = Store.state.hazard.waveIndex,
				},
				rebirthCost = Economy.rebirthCost(profile),
				lockCost = GameConfig.Lock.cost,
				belts = Store.beltEntries(),
			})
		end
	end
end

local function handleBuyFromConveyor(player: Player, entryId: number)
	local profile = Store.getPlayer(player.UserId)
	if not profile or typeof(entryId) ~= "number" then
		return
	end
	local ok, message = Spawner.buyEntry(profile, entryId)
	if ok then
		Bases.syncPlayer(profile)
		local root = PlayerService.rootFor(player.UserId)
		if root then
			sendBurst(player.UserId, root.Position + Vector3.new(0, 3, 0), Color3.fromRGB(120, 240, 156))
		end
	end
	sendNotify(player.UserId, message, if ok then "good" else "bad")
end

local function handleBuyFromShop(player: Player, defId: string)
	local profile = Store.getPlayer(player.UserId)
	if not profile or typeof(defId) ~= "string" then
		return
	end
	local ok, message = Shop.buy(profile, defId)
	if ok then
		local root = PlayerService.rootFor(player.UserId)
		if root then
			sendBurst(player.UserId, root.Position + Vector3.new(0, 3, 0), Color3.fromRGB(120, 200, 255))
		end
	end
	sendNotify(player.UserId, message, if ok then "good" else "bad")
end

local function handleBuyLock(player: Player)
	local profile = Store.getPlayer(player.UserId)
	if not profile then
		return
	end
	local ok, message = Steal.buyLock(profile)
	sendNotify(player.UserId, message, if ok then "good" else "bad")
end

local function handleRebirth(player: Player)
	local profile = Store.getPlayer(player.UserId)
	if not profile then
		return
	end
	local ok, message = Economy.rebirth(profile)
	if ok then
		Bases.syncPlayer(profile)
		local root = PlayerService.rootFor(player.UserId)
		if root then
			sendBurst(player.UserId, root.Position + Vector3.new(0, 4, 0), Color3.fromRGB(250, 210, 90))
		end
	end
	sendNotify(player.UserId, message, if ok then "good" else "bad")
end

local function handleDash(player: Player)
	local profile = Store.getPlayer(player.UserId)
	if not profile then
		return
	end
	local ok, message = PlayerService.dashHome(profile, player)
	sendNotify(player.UserId, message, if ok then "good" else "info")
end

local function handleSteal(player: Player, plotIndex: number, slotIndex: number)
	local profile = Store.getPlayer(player.UserId)
	if not profile or typeof(plotIndex) ~= "number" or typeof(slotIndex) ~= "number" then
		return
	end
	local ok, message = Steal.steal(profile, plotIndex, slotIndex)
	if ok then
		local root = PlayerService.rootFor(player.UserId)
		if root then
			sendBurst(player.UserId, root.Position + Vector3.new(0, 3, 0), Color3.fromRGB(255, 170, 90))
		end
		for _, other in ipairs(Store.allPlayers()) do
			if other.plotIndex == plotIndex then
				sendNotify(other.userId, profile.name .. " stole from your base!", "bad")
			end
		end
	end
	sendNotify(player.userId, message, if ok then "good" else "bad")
end

local function handleSell(player: Player, plotIndex: number, slotIndex: number)
	local profile = Store.getPlayer(player.UserId)
	if not profile or profile.plotIndex ~= plotIndex or typeof(slotIndex) ~= "number" then
		return
	end
	local record = profile.slots[slotIndex]
	if not record then
		return
	end
	local def = BrainrotDefs.get(record.defId)
	if not def then
		return
	end
	local price = Economy.sellPrice(profile, def, record.mutationId)
	Store.removeSlot(profile, slotIndex)
	Store.addMoney(profile, price)
	Bases.syncPlayer(profile)
	sendNotify(player.UserId, "Sold " .. def.name .. " for " .. Format.money(price), "good")
end

-- Actions a client fires. Distribution is validated on the server: the client
-- only ever names a belt id, a def id, a plot/slot, never a price.
remotes.BuyFromConveyor.OnServerEvent:Connect(handleBuyFromConveyor)
remotes.BuyFromShop.OnServerEvent:Connect(handleBuyFromShop)
remotes.BuyLock.OnServerEvent:Connect(handleBuyLock)
remotes.RequestRebirth.OnServerEvent:Connect(handleRebirth)
remotes.RequestDash.OnServerEvent:Connect(handleDash)
remotes.StealRequest.OnServerEvent:Connect(handleSteal)
remotes.SellSlot.OnServerEvent:Connect(handleSell)

local function onPlayerAdded(player: Player)
	local profile = PlayerService.attachPlayer(player)

	player.CharacterAdded:Connect(function(character)
		PlayerService.registerCharacter(player, character)
	end)
	if player.Character then
		PlayerService.registerCharacter(player, player.Character)
	end

	sendNotify(player.UserId, "Welcome to Brainrot Rush! Walk the belt, buy a brainrot, defend your base.", "good")
	pushSnapshot()
	player:SetAttribute("PlotIndex", profile.plotIndex)
end

local function onPlayerRemoving(player: Player)
	PlayerService.detachPlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

setupLighting()
setupMap()
ShopShowcase.build()
Events.ensureRivals()
Spawner.startBelt()

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

local snapshotAccumulator = 0
local retryAccumulator = 0
RunService.Heartbeat:Connect(function(dt)
	Spawner.stepBelt(dt)
	Events.stepHazard(dt)
	Events.stepRivals(dt)

	retryAccumulator += dt
	if retryAccumulator >= 1 then
		retryAccumulator = 0
		Bases.retryPending()
	end

	for _, profile in ipairs(Store.allPlayers()) do
		Economy.tickIncome(profile, dt, Events.incomeBoost(profile))
		Bases.setLockVisual(profile)
	end

	snapshotAccumulator += dt
	if snapshotAccumulator >= GameConfig.SnapshotInterval then
		snapshotAccumulator = 0
		pushSnapshot()
	end
end)
