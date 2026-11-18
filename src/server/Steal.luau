-- Stealing: a player can grab a brainrot off another player's base unless that base
-- is locked. Base locks are bought in Bases.toggleLock; this module only reads them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Store = require(script.Parent.Store)
local Bases = require(script.Parent.Bases)

local Steal = {}

local function remotes()
	return ReplicatedStorage:FindFirstChild("Remotes")
end

local function toast(player, text, tone)
	local folder = remotes()
	local remote = folder and folder:FindFirstChild("ShowToast")
	if remote then
		remote:FireClient(player, { text = text, tone = tone or "info" })
	end
end

-- Steals the most valuable brainrot from a plot the player does not own.
function Steal.trySteal(thief, plotIndex)
	local record = Store.record(thief)
	local slot = Store.slots[plotIndex]
	if not slot then
		return false, "No such base"
	end
	if slot.owner == thief.UserId then
		return false, "That is your own base"
	end
	if slot.owner == nil then
		return false, "That base is empty"
	end
	if Bases.lockState(plotIndex) > 0 then
		return false, string.format("Base locked for %ds", Bases.lockState(plotIndex))
	end

	local now = os.clock()
	local cooldown = Store.Config.Economy.stealCooldown
	if record.lastSteal > 0 and now - record.lastSteal < cooldown then
		return false, string.format("Steal recharges in %ds", math.ceil(cooldown - (now - record.lastSteal)))
	end
	if not record.plotIndex then
		return false, "You have no base"
	end
	if #Store.ownedBrainrots(thief) >= #Store.Config.World.slotOffsets then
		return false, "Your base slots are full"
	end
	if #slot.models == 0 then
		return false, "Nothing left to steal"
	end

	-- Take the highest earner they have.
	local bestIndex, bestRate = 1, -1
	for index, entry in ipairs(slot.models) do
		if entry.rate > bestRate then
			bestIndex, bestRate = index, entry.rate
		end
	end

	local victim = Store.byUser[slot.owner]
	local victimName = victim and victim.Name or "a rival"
	local taken = Bases.removeAt(victim, bestIndex)
	if not taken then
		return false, "They got away"
	end

	record.lastSteal = now
	local purchase = {
		brainrotId = Store.nextBrainrotId(),
		def = taken.def,
		mutation = taken.mutation,
		rate = taken.rate,
	}
	local placed, slotIndex = Bases.placeBrainrot(thief, purchase)
	if not placed then
		-- Their base filled up between the checks: hand it back rather than lose it.
		if victim then
			Bases.placeBrainrot(victim, taken)
		end
		return false, slotIndex
	end

	toast(thief, string.format("STOLE %s from %s", taken.def.name, victimName), "steal")
	if victim then
		toast(victim, string.format("%s STOLE YOUR %s", thief.Name, string.upper(taken.def.name)), "danger")
	end
	return true, taken.def.name, slotIndex
end

-- Puts a steal prompt on each brainrot a plot holds so the grab is discoverable in 3D.
function Steal.attachPrompt(model, plotIndex)
	local root = model:FindFirstChild("Body") or model.PrimaryPart
	if not root then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "STEAL"
	prompt.ObjectText = "Rival brainrot"
	prompt.HoldDuration = 0.9
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt:SetAttribute("PlotIndex", plotIndex)
end

function Steal.wirePrompts()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if prompt.Name ~= "StealPrompt" then
			return
		end
		local plotIndex = prompt:GetAttribute("PlotIndex")
		if type(plotIndex) ~= "number" then
			local model = prompt.Parent and prompt.Parent.Parent
			local ownerId = model and model:GetAttribute("OwnerUserId")
			if ownerId == nil then
				return
			end
			local record = Store.recordFromUserId(ownerId)
			if not record or not record.plotIndex then
				return
			end
			plotIndex = record.plotIndex
		end
		local ok, message = Steal.trySteal(player, plotIndex)
		if ok then
			local celebrate = remotes()
			local burst = celebrate and celebrate:FindFirstChild("Celebrate")
			if burst then
				burst:FireClient(player, { kind = "steal", text = string.format("SWIPED %s", message) })
			end
		else
			toast(player, message, "danger")
		end
	end)
end

return Steal
