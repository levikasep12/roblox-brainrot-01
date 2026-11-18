-- Server entrypoint: builds the world once, then wires the remotes and player
-- lifecycle to the modules (Economy, Bases, Spawner, Steal, Events).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- Rojo turns this folder into this Script, so the modules are its own children.
local Store = require(script.Store)
local Economy = require(script.Economy)
local Bases = require(script.Bases)
local Spawner = require(script.Spawner)
local Steal = require(script.Steal)
local Events = require(script.Events)
local WorldBuilder = require(script.WorldBuilder)

Remotes.init()
local stateSync = Remotes.get("StateSync")
local showToast = Remotes.get("ShowToast")
local celebrate = Remotes.get("Celebrate")
local buyRemote = Remotes.get("BuyBrainrot")
local rebirthRemote = Remotes.get("Rebirth")
local lockRemote = Remotes.get("ToggleLock")
local stealRemote = Remotes.get("StealRequest")
local buyResult = Remotes.get("BuyResult")

local function toast(player, text, tone)
	showToast:FireClient(player, { text = text, tone = tone or "info" })
end

-- The shop catalogue never changes at runtime: build it once, not on every state push.
local shopPayload = {}
for _, def in ipairs(Store.Defs.sortedByPrice()) do
	table.insert(shopPayload, {
		id = def.id,
		name = def.name,
		rarity = def.rarity,
		price = math.floor(def.price * 1.2),
		rate = def.rate,
	})
end

local function pushState(player)
	if not player.Parent then
		return
	end
	local snapshot = Store.snapshotFor(player)
	snapshot.shop = shopPayload
	stateSync:FireClient(player, snapshot)
end

local world, plotParts = WorldBuilder.build()
Bases.setPlotParts(plotParts)
Economy.startIncomeLoop()
Spawner.start(world)
Steal.wirePrompts()
Events.start(world)

local function onCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.WalkSpeed = 22
		humanoid.JumpPower = 54
	end
	-- A character's pivot is its HumanoidRootPart: stand it clear of the spawn pad. The part
	-- can lag the CharacterAdded signal by a frame, so wait briefly rather than error.
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if root then
		character:PivotTo(CFrame.new(Config.World.spawnPosition.X, 4, Config.World.spawnPosition.Z))
	end
end

local function onPlayerAdded(player)
	Store.record(player)
	Bases.onPlayerJoin(player)
	task.delay(1, function()
		pushState(player)
	end)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
		task.delay(0.6, function()
			pushState(player)
		end)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Attach a steal prompt to every base brainrot, including ones placed after join.
-- Bases.placeBrainrot leaves the prompt off so Steal owns prompt policy in one place.
local function watchOwnedModels()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local record = Store.players[player.UserId]
				if record and record.plotIndex then
					local slot = Store.slots[record.plotIndex]
					for _, entry in ipairs(slot.models) do
						local model = entry.model
						if model and not model:GetAttribute("PromptWired") then
							model:SetAttribute("PromptWired", true)
							Steal.attachPrompt(model, record.plotIndex)
						end
					end
				end
			end
		end
	end)
end
watchOwnedModels()

buyRemote.OnServerEvent:Connect(function(player, defId)
	local ok, message = Spawner.orderFromShop(player, defId)
	if ok then
		-- One notice per action: the celebrate burst and toast, and nothing else.
		celebrate:FireClient(player, { kind = "buy", text = message })
	else
		buyResult:FireClient(player, { ok = false, message = message })
	end
	pushState(player)
end)

rebirthRemote.OnServerEvent:Connect(function(player)
	local ok, message = Economy.rebirth(player)
	if ok then
		toast(player, message, "rebirth")
		celebrate:FireClient(player, { kind = "rebirth", text = message })
	else
		toast(player, message, "danger")
	end
	pushState(player)
end)

lockRemote.OnServerEvent:Connect(function(player)
	local ok, message = Bases.toggleLock(player)
	toast(player, message, ok and "lock" or "danger")
	pushState(player)
end)

stealRemote.OnServerEvent:Connect(function(player, plotIndex)
	if type(plotIndex) ~= "number" then
		return
	end
	local ok, message = Steal.trySteal(player, plotIndex)
	if ok then
		celebrate:FireClient(player, { kind = "steal", text = string.format("SWIPED %s", message) })
	else
		toast(player, message, "danger")
	end
	pushState(player)
end)

-- Push state on a steady beat so money and the wave banner always move.
task.spawn(function()
	while true do
		task.wait(0.25)
		for _, player in ipairs(Players:GetPlayers()) do
			pushState(player)
		end
	end
end)

print(string.format("[BrainrotRush] server ready: %d plots, %d brainrots", #Config.World.plotCenters, #Store.Defs.Cast))
