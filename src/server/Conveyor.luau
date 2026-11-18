-- Conveyor: spawns brainrots onto the runway, walks them across, rolls
-- mutations, and lets a player buy one with a ProximityPrompt. The module owns
-- the conveyor's population (spawn pacing, walk animation, despawn at the far
-- end) and exposes the live items so Economy can complete a purchase and Steal
-- can look one up.
--
-- Walking is a single Heartbeat loop that slides each model's root and bobs it
-- slightly, so 4-8 creatures cost one connection, not one each.

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotDefs = require(game:GetService("ReplicatedStorage").Shared.BrainrotDefs)
local Mutations = require(game:GetService("ReplicatedStorage").Shared.Mutations)
local ModelBuilder = require(script.Parent.ModelBuilder)

local Conveyor = {}

local spawnFolder: Folder
local economy
local items: { [string]: any } = {}
local lastSpawn = 0

local function pickDef(): any
	-- Weighted toward earlier (cheaper) tiers so the early game moves; every
	-- creature still has a chance to appear.
	local totalWeight = 0
	local weights = {}
	for index, def in ipairs(BrainrotDefs.List) do
		local weight = math.max(1, 12 - index)
		weights[index] = weight
		totalWeight += weight
	end
	local roll = math.random() * totalWeight
	local acc = 0
	for index, def in ipairs(BrainrotDefs.List) do
		acc += weights[index]
		if roll <= acc then
			return def
		end
	end
	return BrainrotDefs.List[1]
end

local function placeItem(model: Model, x: number)
	model:PivotTo(CFrame.new(x, Config.ConveyorHeight + 1.0, Config.ConveyorZ) * CFrame.Angles(0, math.rad(90), 0))
end

local function priceFor(def: any, mutation: any): number
	local bump = mutation == Mutations.None and 1 or mutation.rateMultiplier
	return math.floor(def.price * (0.9 + bump * 0.1))
end

function Conveyor.init(folder: Folder)
	spawnFolder = folder
end

function Conveyor.setEconomy(module: any)
	economy = module
end

function Conveyor.spawn(defId: string?, mutationId: string?)
	local def = defId and BrainrotDefs.get(defId) or pickDef()
	local mutation = mutationId and Mutations.get(mutationId) or Mutations.roll(Config.MutationChance, Config.DiamondChance)
	local model, resolvedDef, resolvedMutation = ModelBuilder.build(def.id, mutation.id)
	model.Name = "Conveyor_" .. def.id
	model.Parent = spawnFolder

	local item = {
		id = `{def.id}_{workspace:GetServerTimeNow()}_{math.random(1, 99999)}`,
		model = model,
		def = resolvedDef,
		mutation = resolvedMutation,
		price = priceFor(resolvedDef, resolvedMutation),
		x = Config.ConveyorStartX,
		phase = math.random() * math.pi * 2,
		claimed = false,
	}
	placeItem(model, item.x)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = ("Buy $%d"):format(item.price)
	prompt.ObjectText = resolvedDef.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = model.PrimaryPart

	prompt.Triggered:Connect(function(player)
		if item.claimed then
			return
		end
		if not economy then
			return
		end
		local ok, message = economy.buyConveyorItem(player, item)
		if ok then
			item.claimed = true
			Conveyor.remove(item.id, true)
		else
			economy.notify(player, message)
		end
	end)

	items[item.id] = item
	return item
end

--- Finds the cheapest live conveyor item of a definition, so a shop purchase
--- still goes through the same buy path (money, slot, burst, roster).
function Conveyor.findLive(defId: string)
	local best = nil
	for _, item in pairs(items) do
		if not item.claimed and item.def.id == defId then
			if not best or item.price < best.price then
				best = item
			end
		end
	end
	return best
end

function Conveyor.get(id: string)
	return items[id]
end

function Conveyor.list()
	return items
end

function Conveyor.remove(id: string, celebratory: boolean)
	local item = items[id]
	if not item then
		return
	end
	items[id] = nil
	if celebratory then
		local model = item.model
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") and part ~= model.PrimaryPart then
				part.Anchored = false
				part.CanCollide = false
				part.AssemblyLinearVelocity = Vector3.new(
					math.random(-12, 12),
					math.random(24, 40),
					math.random(-12, 12)
				)
			end
		end
		Debris:AddItem(model, 1.6)
	else
		item.model:Destroy()
	end
end

function Conveyor.count(): number
	local total = 0
	for _ in pairs(items) do
		total += 1
	end
	return total
end

function Conveyor.start()
	lastSpawn = workspace:GetServerTimeNow() - Config.SpawnInterval
	RunService.Heartbeat:Connect(function(dt)
		local now = workspace:GetServerTimeNow()
		if now - lastSpawn >= Config.SpawnInterval and Conveyor.count() < Config.MaxConveyor then
			lastSpawn = now
			Conveyor.spawn()
		end

		for id, item in pairs(items) do
			if not item.claimed then
				item.x += Config.WalkSpeed * dt
				if item.x > Config.ConveyorEndX then
					Conveyor.remove(id, false)
				else
					local bob = math.sin(now * 3 + item.phase) * 0.16
					item.model:PivotTo(
						CFrame.new(item.x, Config.ConveyorHeight + 1.0 + bob, Config.ConveyorZ)
							* CFrame.Angles(0, math.rad(90), math.rad(math.sin(now * 3 + item.phase) * 3))
					)
				end
			end
		end
	end)
end

return Conveyor
