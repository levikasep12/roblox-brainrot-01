-- The runway: rolls a brainrot, builds its model, walks it across the conveyor and
-- lets a nearby player grab it with a proximity prompt. Mutations roll here too.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local BrainrotModel = require(ReplicatedStorage.Shared.BrainrotModel)

local Store = require(script.Parent.Store)
local Bases = require(script.Parent.Bases)

local Spawner = {}

local arena = nil
local beltSlats = {}

local rarityWeights = {
	Common = 46,
	Rare = 28,
	Epic = 15,
	Legendary = 8,
	Mythic = 3,
}

local function weightedDef()
	local total = 0
	for _, rarity in ipairs(BrainrotDefs.RarityOrder) do
		total += rarityWeights[rarity]
	end
	local roll = math.random() * total
	local chosenRarity = "Common"
	for _, rarity in ipairs(BrainrotDefs.RarityOrder) do
		roll -= rarityWeights[rarity]
		if roll <= 0 then
			chosenRarity = rarity
			break
		end
	end
	local pool = {}
	for _, def in ipairs(BrainrotDefs.Cast) do
		if def.rarity == chosenRarity then
			table.insert(pool, def)
		end
	end
	return pool[math.random(1, #pool)]
end

local function rollMutation()
	local roll = math.random()
	if roll <= Config.Mutation.diamondChance then
		return "Diamond", Config.Mutation.diamondRate
	elseif roll <= Config.Mutation.diamondChance + Config.Mutation.goldenChance then
		return "Golden", Config.Mutation.goldenRate
	end
	return nil, 1
end

local function placeOnConveyor(entry)
	local model = entry.model
	model:PivotTo(CFrame.new(0, Config.World.conveyorDeckY + 0.5, entry.z))
end

local function spawnOne()
	local def = weightedDef()
	local mutation, rateMultiplier = rollMutation()
	local brainrotId = Store.nextBrainrotId()
	local rate = def.rate * rateMultiplier

	local entry = {
		brainrotId = brainrotId,
		def = def,
		mutation = mutation,
		rate = rate,
		z = Config.World.conveyorStartZ,
		claimed = false,
	}

	local model = BrainrotModel.build(def, math.floor(rate + 0.5), mutation)
	model.Name = "Runway_" .. def.id
	model:SetAttribute("BrainrotId", brainrotId)
	model:SetAttribute("DefId", def.id)
	model:SetAttribute("Mutation", mutation or "None")
	model:SetAttribute("Price", def.price)

	local root = model:FindFirstChild("Body") or model.PrimaryPart
	if root then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "BuyPrompt"
		prompt.ActionText = string.format("GRAB  $%d", def.price)
		prompt.ObjectText = mutation and (mutation .. " " .. def.name) or def.name
		prompt.HoldDuration = 0.15
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
	end

	model.Parent = arena
	entry.model = model
	placeOnConveyor(entry)
	Store.conveyor[brainrotId] = entry
	return entry
end

local function despawn(entry)
	Store.conveyor[entry.brainrotId] = nil
	if entry.model then
		entry.model:Destroy()
	end
end

-- The nearest unclaimed runway brainrot to a player, within the buy reach.
function Spawner.nearest(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local best, bestDistance = nil, Config.Conveyor.buyDistance
	for _, entry in pairs(Store.conveyor) do
		if not entry.claimed and entry.model and entry.model.PrimaryPart then
			local distance = (entry.model.PrimaryPart.Position - root.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = entry, distance
			end
		end
	end
	return best
end

function Spawner.byDef(defId)
	local best = nil
	for _, entry in pairs(Store.conveyor) do
		if not entry.claimed and entry.def.id == defId and entry.model then
			if best == nil or entry.z > best.z then
				best = entry
			end
		end
	end
	return best
end

-- Hands a runway entry to a player: remove it from the runway, put it on their plot.
function Spawner.claim(player, entry)
	if entry.claimed then
		return false, "Already grabbed"
	end
	local record = Store.record(player)
	if record.money < entry.def.price then
		return false, string.format("Need $%d", entry.def.price)
	end
	local owned = #Store.ownedBrainrots(player)
	if record.plotIndex == nil then
		return false, "No base"
	end
	if owned >= #Config.World.slotOffsets then
		return false, "All base slots full"
	end
	entry.claimed = true
	despawn(entry)

	local purchase = {
		brainrotId = Store.nextBrainrotId(),
		def = entry.def,
		mutation = entry.mutation,
		rate = entry.rate,
	}
	local placed, slotIndex = Bases.placeBrainrot(player, purchase)
	if not placed then
		return false, slotIndex
	end
	Store.trySpend(player, entry.def.price)
	record.bought += 1
	return true, purchase
end

-- The shop's custom order: pays the list price for a plain (unmutated) copy placed
-- straight onto the base, so a player never has to wait on the runway.
function Spawner.orderFromShop(player, defId)
	local def = BrainrotDefs.ById[defId]
	if not def then
		return false, "Unknown brainrot", nil
	end
	local record = Store.record(player)
	if not record.plotIndex then
		return false, "No base", nil
	end
	if #Store.ownedBrainrots(player) >= #Config.World.slotOffsets then
		return false, "All base slots full", nil
	end
	local price = math.floor(def.price * 1.2)
	if not Store.trySpend(player, price) then
		return false, string.format("Need $%d", price), nil
	end
	local purchase = {
		brainrotId = Store.nextBrainrotId(),
		def = def,
		mutation = nil,
		rate = def.rate,
	}
	local placed, slotIndex = Bases.placeBrainrot(player, purchase)
	if not placed then
		Store.award(player, price)
		return false, slotIndex, nil
	end
	record.bought += 1
	return true, string.format("%s ordered for $%d", def.name, price), purchase
end

-- Someone stepped on a runway prompt: grab that brainrot.
local function wirePrompts()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if prompt.Name ~= "BuyPrompt" then
			return
		end
		local model = prompt.Parent and prompt.Parent.Parent
		if not model then
			return
		end
		local brainrotId = model:GetAttribute("BrainrotId")
		local entry = brainrotId and Store.conveyor[brainrotId]
		if not entry then
			return
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or not entry.model or not entry.model.PrimaryPart then
			return
		end
		if (entry.model.PrimaryPart.Position - root.Position).Magnitude > Config.Conveyor.buyDistance then
			return
		end
		local ok, result = Spawner.claim(player, entry)
		if ok then
			local remote = ReplicatedStorage:FindFirstChild("Remotes")
			local celebrate = remote and remote:FindFirstChild("Celebrate")
			if celebrate then
				celebrate:FireClient(player, {
					kind = "buy",
					text = string.format("GOT %s", result.def.name),
				})
			end
		end
	end)
end

local function animateBelt(dt)
	for _, slat in ipairs(beltSlats) do
		local cframe = slat.CFrame
		local z = cframe.Position.Z + Config.Conveyor.speed * 0.6 * dt
		if z > Config.World.conveyorStartZ + Config.World.conveyorLength then
			z = Config.World.conveyorStartZ - 2
		end
		slat.CFrame = CFrame.new(cframe.Position.X, cframe.Position.Y, z)
	end
end

function Spawner.start(world)
	arena = world
	beltSlats = {}
	local conveyor = world:FindFirstChild("Conveyor")
	if conveyor then
		for _, child in ipairs(conveyor:GetChildren()) do
			if child.Name == "BeltSlat" then
				table.insert(beltSlats, child)
			end
		end
	end

	wirePrompts()

	for i = 1, Config.Conveyor.npcCount do
		local entry = spawnOne()
		entry.z = Config.World.conveyorStartZ + i * Config.Conveyor.spacing
		placeOnConveyor(entry)
	end

	-- Restock the runway whenever it has room.
	task.spawn(function()
		while true do
			task.wait(Config.Conveyor.respawnDelay)
			local count = 0
			for _ in pairs(Store.conveyor) do
				count += 1
			end
			local spawnRoom = Config.Conveyor.npcCount + 2
			local freeStart = Config.World.conveyorStartZ + Config.Conveyor.npcCount * Config.Conveyor.spacing
			local occupied = false
			for _, entry in pairs(Store.conveyor) do
				if entry.z < freeStart + 4 then
					occupied = true
				end
			end
			if count < spawnRoom and not occupied then
				spawnOne()
			end
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		animateBelt(dt)
		local endZ = Config.World.conveyorStartZ + Config.World.conveyorLength + 6
		for _, entry in pairs(Store.conveyor) do
			entry.z += Config.Conveyor.speed * dt
			if entry.model and entry.model.PrimaryPart then
				local bob = math.sin(os.clock() * 3 + entry.brainrotId) * 0.12
				entry.model:PivotTo(CFrame.new(
					math.sin(entry.z * 0.1) * 3,
					Config.World.conveyorDeckY + 0.5 + bob,
					entry.z
				))
			end
			if entry.z > endZ then
				despawn(entry)
			end
		end
	end)
end

-- Runs one immediate spawn on behalf of any player (used by the shop's "summon" fallback).
function Spawner.spawnNow()
	if arena then
		spawnOne()
	end
end

return Spawner
