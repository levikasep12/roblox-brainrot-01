-- Runs the conveyor: rolls a brainrot from the cast (weighted toward the
-- cheaper tiers, with a small chance of a Golden or Diamond mutation), builds
-- its model, then walks it from the start of the runway to the far end. When
-- it reaches the end unclaimed it walks off and despawns.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local BrainrotDefs = require(Shared.BrainrotDefs)
local BrainrotModel = require(Shared.BrainrotModel)
local Format = require(Shared.Format)
local WorldBuilder = require(script.Parent.WorldBuilder)
local Store = require(script.Parent.Store)
local Economy = require(script.Parent.Economy)

local Spawner = {}

local random = Random.new(os.clock() * 1000 % 100000)

-- The cast is sorted by rarity; the walk weight drops with tier so Common
-- brainrots show up far more often than Mythic ones.
local function rollDefinition()
	local total = 0
	local weights = {}
	for index, def in ipairs(BrainrotDefs.Cast) do
		local weight = 1 / (1 + index * 0.55)
		weights[index] = weight
		total += weight
	end
	local roll = random:NextNumber() * total
	for index, def in ipairs(BrainrotDefs.Cast) do
		roll -= weights[index]
		if roll <= 0 then
			return def
		end
	end
	return BrainrotDefs.Cast[1]
end

local function rollMutation()
	local roll = random:NextNumber()
	if roll < Config.MutationChance.Diamond then
		return "Diamond"
	elseif roll < Config.MutationChance.Diamond + Config.MutationChance.Golden then
		return "Golden"
	end
	return nil
end

-- Builds one offer on the runway. `defId` and `mutation` let other modules
-- request a specific character (the tutorial spawn, for instance).
function Spawner.SpawnOffer(defId, mutation)
	if #Store.Offers >= Config.MaxConveyorOffers then
		return nil
	end
	local def = defId and BrainrotDefs.Get(defId) or rollDefinition()
	if not def then
		return nil
	end
	if mutation == nil and defId == nil then
		mutation = rollMutation()
	end

	local rate = Economy.MutationRate(def, mutation)
	local price = Economy.PriceOf(def)
	local startPoint = WorldBuilder.ConveyorPoint(0)
	local frame = BrainrotModel.FacingCFrame(startPoint, Vector3.new(0, 0, 1))
	local model = BrainrotModel.Build(def, mutation, frame, rate)
	local offer = Store.AddOffer(def, mutation, price, rate, model)
	model.Name = "Offer_" .. tostring(offer.id)
	model:SetAttribute("OfferId", offer.id)
	model.Parent = workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClaimBrainrot"
	prompt.ActionText = "Buy  " .. Format.Money(price)
	prompt.ObjectText = def.name .. "  " .. def.rarity
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	BrainrotModel.SetLabelPrice(model, Format.Money(price))

	return offer
end

-- Walks the model forward each frame; the price tag sits above the label so
-- it is obvious what the thing costs before you touch it.
local function stepOffer(offer, dt)
	local model = offer.model
	if not model or not model.Parent or not model.PrimaryPart then
		return false
	end
	local basePoint = WorldBuilder.ConveyorPoint(offer.progress)
	local bob = math.abs(math.sin(os.clock() * 2.6 + offer.id)) * 0.32
	local frame = BrainrotModel.FacingCFrame(basePoint + Vector3.new(0, bob, 0), Vector3.new(0, 0, 1))
	model:PivotTo(frame)
	offer.progress += (offer.speed / (Config.ConveyorEndZ - Config.ConveyorStartZ)) * dt
	return offer.progress < 1
end

function Spawner.Start()
	-- An initial batch so the runway is never empty when a player arrives.
	for index = 1, 4 do
		local offer = Spawner.SpawnOffer(nil, nil)
		if offer then
			offer.progress = (index - 1) * 0.18 + 0.02
		end
	end

	task.spawn(function()
		while true do
			task.wait(Config.ConveyorSpawnInterval * (0.7 + random:NextNumber() * 0.6))
			Spawner.SpawnOffer(nil, nil)
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		local finished = {}
		for _, offer in pairs(Store.Offers) do
			if not stepOffer(offer, dt) then
				table.insert(finished, offer.id)
			end
		end
		for _, offerId in ipairs(finished) do
			-- Detach first: the model keeps living in the world while it fades
			-- away, and the book no longer offers a character that is leaving.
			local offer = Store.DetachOffer(offerId)
			if offer and offer.model then
				local model = offer.model
				task.spawn(function()
					for _ = 1, 12 do
						if not model.Parent or not model.PrimaryPart then
							return
						end
						model:PivotTo(model:GetPivot() + Vector3.new(0, -0.35, 0.8))
						task.wait(0.035)
					end
					if model.Parent then
						model:Destroy()
					end
				end)
			end
		end
	end)
end

return Spawner
