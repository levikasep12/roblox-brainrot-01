-- Controls: action bindings that survive Roblox's default camera scripts. The
-- camera eats Left/Right arrows and sometimes F through InputBegan with
-- gameProcessedEvent set, so every gameplay bind goes through
-- ContextActionService with sink priority: F steals, L locks, B toggles the
-- shop (bound in ShopController), R asks for a state refresh. Locomotion stays
-- on the default 3D character controls; the HUD is the only overlay.

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controls = {}

local remotes

local function onSteal(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	remotes.StealBrainrot:FireServer()
	return Enum.ContextActionResult.Sink
end

local function onLock(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	remotes.BuyLock:FireServer()
	return Enum.ContextActionResult.Sink
end

local function onRefresh(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	remotes.RequestState:FireServer()
	return Enum.ContextActionResult.Sink
end

function Controls.start()
	remotes = ReplicatedStorage:WaitForChild("Remotes")

	ContextActionService:BindAction("BrainrotSteal", onSteal, false, Enum.KeyCode.F)
	ContextActionService:BindAction("BrainrotLock", onLock, false, Enum.KeyCode.L)
	ContextActionService:BindAction("BrainrotRefresh", onRefresh, false, Enum.KeyCode.R)

	-- Keep a touch escape hatch: mobile players get the same actions as buttons.
	ContextActionService:SetTitle("BrainrotSteal", "STEAL")
	ContextActionService:SetTitle("BrainrotLock", "LOCK")
end

return Controls
