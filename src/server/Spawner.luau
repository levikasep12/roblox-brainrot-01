-- Runs the conveyor: spawns belt brainrots at the west end, walks them east
-- with a Tween-less CFrame step, gives each a 3D model and billboard label,
-- and hands a belt entry to whoever buys it first.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)
local BrainrotModel = require(ReplicatedStorage.Shared.BrainrotModel)
local WorldRefs = require(ReplicatedStorage.Shared.WorldRefs)
local Store = require(script.Parent.Store)

local Spawner = {}

local beltFolder: Folder? = nil
local models: { [number]: Model } = {}
local bobPhase: { [number]: number } = {}
local nextSpawnAt = 0

local function ensureFolder(): Folder
	if beltFolder and beltFolder.Parent then
		return beltFolder
	end
	local root = WorldRefs.root()
	local parent = root or Workspace
	local existing = parent:FindFirstChild("BeltBrainrots")
	if existing and existing:IsA("Folder") then
		beltFolder = existing
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "BeltBrainrots"
	created.Parent = parent
	beltFolder = created
	return created
end

local function beltPosition(x: number, yOffset: number, zOffset: number): CFrame
	return CFrame.new(x, GameConfig.Conveyor.y + yOffset, zOffset)
end

function Spawner.createEntryModel(entry)
	local def = BrainrotDefs.get(entry.defId)
	if not def then
		return
	end
	local model = BrainrotModel.build(def)
	model.Name = "Belt_" .. tostring(entry.id)
	model:SetAttribute("BeltId", entry.id)
	model:SetAttribute("DefId", entry.defId)
	model:SetAttribute("MutationId", entry.mutationId)
	BrainrotModel.applyMutation(model, entry.mutationId)
	BrainrotModel.addLabel(model, def, entry.mutationId)

	local lane = (entry.id % 3 - 1) * 4.6
	entry.lane = lane
	model:PivotTo(beltPosition(entry.x, 0, lane))
	model.Parent = ensureFolder()
	models[entry.id] = model
	bobPhase[entry.id] = math.random() * math.pi * 2
end

function Spawner.despawnEntry(entry)
	local model = models[entry.id]
	if model then
		model:Destroy()
		models[entry.id] = nil
	end
	bobPhase[entry.id] = nil
end

function Spawner.spawnOne(startX: number?)
	if #Store.beltEntries() >= GameConfig.Conveyor.maxOnBelt then
		return nil
	end
	local def = BrainrotDefs.randomDef()
	local mutationId = BrainrotDefs.rollMutation()
	local entry = Store.newBeltEntry(def.id, mutationId)
	if startX then
		entry.x = startX
	end
	Spawner.createEntryModel(entry)
	return entry
end

function Spawner.startBelt()
	local now = os.clock()
	nextSpawnAt = now + GameConfig.Conveyor.spawnInterval
	for i = 1, 4 do
		Spawner.spawnOne(GameConfig.Conveyor.startX + i * 16)
	end
end

function Spawner.buyEntry(profile, entryId: number): (boolean, string)
	local entry
	for _, candidate in ipairs(Store.beltEntries()) do
		if candidate.id == entryId then
			entry = candidate
			break
		end
	end
	if not entry then
		return false, "That brainrot is gone"
	end
	local slotIndex = Store.freeSlotIndex(profile)
	if slotIndex == 0 then
		return false, "Your base is full"
	end
	local def = BrainrotDefs.get(entry.defId)
	if not def then
		return false, "Unknown brainrot"
	end
	local price = BrainrotDefs.priceFor(def, entry.mutationId)
	if profile.money < price then
		return false, "Need $" .. tostring(price)
	end
	Store.spendMoney(profile, price)
	Store.placeSlot(profile, slotIndex, entry.defId, entry.mutationId)
	Store.removeBeltEntry(entry.id)
	Spawner.despawnEntry(entry)
	return true, BrainrotDefs.displayName(def, entry.mutationId) .. " joined your base!"
end

function Spawner.stepBelt(dt: number)
	local now = os.clock()
	if now >= nextSpawnAt then
		Spawner.spawnOne()
		nextSpawnAt = now + GameConfig.Conveyor.spawnInterval
	end

	local snapshot = table.clone(Store.beltEntries())
	for _, beltEntry in ipairs(snapshot) do
		beltEntry.x += GameConfig.Conveyor.walkSpeed * dt
		local model = models[beltEntry.id]
		if model then
			local bob = math.sin(now * 3 + (bobPhase[beltEntry.id] or 0)) * 0.28
			local hop = math.abs(math.sin(now * 6 + (bobPhase[beltEntry.id] or 0))) * 0.22
			model:PivotTo(beltPosition(beltEntry.x, 0.1 + hop, beltEntry.lane or 0) * CFrame.Angles(0, math.rad(90 + bob * 4), 0))
		end
		if beltEntry.x >= GameConfig.Conveyor.endX then
			Store.removeBeltEntry(beltEntry.id)
			Spawner.despawnEntry(beltEntry)
		end
	end
end

function Spawner.entryPosition(entry)
	local model = models[entry.id]
	if model then
		return model:GetPivot().Position
	end
	return Vector3.new(entry.x, GameConfig.Conveyor.y, entry.lane or 0)
end

function Spawner.modelFor(entryId: number)
	return models[entryId]
end

function Spawner.nearestTo(position: Vector3): (any, number)
	local best = nil
	local bestDistance = GameConfig.Conveyor.pickupRange
	for _, entry in ipairs(Store.beltEntries()) do
		local distance = (Spawner.entryPosition(entry) - position).Magnitude
		if distance <= bestDistance then
			best = entry
			bestDistance = distance
		end
	end
	return best, bestDistance
end

return Spawner
