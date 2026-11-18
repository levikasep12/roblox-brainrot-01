-- ClientMain: boots the client. It waits for the server's remotes and HUD
-- state, builds the HUD, the shop and the feedback layer, binds the keys, and
-- keeps the copy in sync. The client never decides money: it renders the
-- snapshot the server sends and forwards intents (buy on prompt, steal, lock,
-- rebirth) as remote calls.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientState = require(script.ClientState)
local HudController = require(script.HudController)
local ShopController = require(script.ShopController)
local Feedback = require(script.Feedback)
local Controls = require(script.Controls)

local player = Players.LocalPlayer

ReplicatedStorage:WaitForChild("Shared")
ReplicatedStorage:WaitForChild("Remotes")

ClientState.init()

local state = ClientState.get()
local gui = HudController.build()
Feedback.init()
ShopController.build(state)
Feedback.start()
Controls.start()

ClientState.request()

-- A short onboarding toast, once per session, that names the loop and keys.
local seenIntro = false
ClientState.onChange(function(kind)
	if kind == "state" and not seenIntro and state.snapshot then
		seenIntro = true
		Feedback.toast("Welcome to Brainrot Rush! Press E at the conveyor to buy.", require(script.Theme).Colors.income)
	end
end)

local function keepGui(guiInstance: ScreenGui)
	player.CharacterAdded:Connect(function()
		guiInstance.Enabled = true
	end)
end

keepGui(gui)

local function refreshLoop()
	while true do
		task.wait(1.5)
		ClientState.request()
	end
end
task.spawn(refreshLoop)
