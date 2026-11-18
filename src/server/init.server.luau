-- ServerMain: the entry point. Builds the world, creates the remotes, then
-- wires the modules in dependency order and handles join/leave. Each module
-- keeps one job (Store/Economy/Conveyor/Bases/Steal/Events/Roster); this file
-- only connects them, so reading it top to bottom shows the game's shape.

local Players = game:GetService("Players")

local Net = require(script.Net)
local Store = require(script.Store)
local WorldBuilder = require(script.WorldBuilder)
local Conveyor = require(script.Conveyor)
local Bases = require(script.Bases)
local Economy = require(script.Economy)
local Steal = require(script.Steal)
local Events = require(script.Events)
local Roster = require(script.Roster)

Net.init()

local handles = WorldBuilder.build()

Bases.init(handles)

local conveyorFolder = Instance.new("Folder")
conveyorFolder.Name = "ConveyorItems"
conveyorFolder.Parent = workspace
Conveyor.init(conveyorFolder)

local deps = {
	net = Net,
	store = Store,
	bases = Bases,
	conveyor = Conveyor,
	economy = Economy,
	roster = Roster,
}

Economy.init(deps)
Conveyor.setEconomy(Economy)
Steal.init(deps)
Events.init(deps)
Roster.init(deps)
Roster.start()

local function renderAllPlots()
	for player, profile in pairs(Store.all()) do
		Bases.renderPlot(profile.plotIndex, profile.slots, player.DisplayName)
		Bases.setLocked(profile.plotIndex, workspace:GetServerTimeNow() < profile.lockUntil)
	end
end

local loaded = {}
local function onPlayerAdded(player: Player)
	if loaded[player] then
		return
	end
	loaded[player] = true
	local ok = Store.load(player)
	if not ok then
		player:Kick("All six bases are taken. Rejoin in a moment.")
		return
	end
	local profile = Store.get(player)
	Bases.renderPlot(profile.plotIndex, profile.slots, player.DisplayName)
	Roster.send(player)

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = 22
		humanoid.JumpPower = 54
	end)

	local notice = Net.get("Notice")
	if notice then
		task.delay(1.2, function()
			if player.Parent then
				notice:FireClient(player, "Buy on the conveyor · E to grab · F to steal · L to lock")
			end
		end)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	local profile = Store.get(player)
	if profile then
		for slotIndex = 1, 6 do
			Bases.clearSlot(profile.plotIndex, slotIndex)
		end
		Bases.setLocked(profile.plotIndex, false)
	end
	Store.unload(player)
	loaded[player] = nil
end)

Net.get("BuyBrainrot").OnServerEvent:Connect(function(player)
	Economy.notify(player, "Buy at the conveyor marker: press E on a brainrot.")
end)

Net.get("BuyFromShop").OnServerEvent:Connect(function(player, defId)
	if type(defId) ~= "string" then
		return
	end
	local item = Conveyor.findLive(defId)
	if not item then
		Economy.notify(player, "That brainrot already walked off the conveyor. Wait for the next one.")
		return
	end
	local ok, message = Economy.buyConveyorItem(player, item)
	if ok then
		item.claimed = true
		Conveyor.remove(item.id, true)
	else
		Economy.notify(player, message)
	end
end)

Net.get("StealBrainrot").OnServerEvent:Connect(function(player)
	local ok, message = Steal.attempt(player)
	if not ok then
		Economy.notify(player, message)
	end
end)

Net.get("BuyLock").OnServerEvent:Connect(function(player)
	local ok, message = Economy.buyLock(player)
	Economy.notify(player, message)
	if ok then
		Roster.send(player)
	end
end)

Net.get("Rebirth").OnServerEvent:Connect(function(player)
	local ok, message = Economy.rebirth(player)
	Economy.notify(player, message)
	Roster.send(player)
	if ok then
		local burst = Net.get("EffectBurst")
		if burst then
			burst:FireClient(player, "rebirth", message)
		end
	end
end)

Net.get("RequestState").OnServerEvent:Connect(function(player)
	Roster.send(player)
end)

Economy.start()
Conveyor.start()
Bases.start()
Events.start()

renderAllPlots()
