-- Feedback: particle bursts and sound on a purchase, steal or rebirth. Uses only
-- Roblox's built-in sounds (rbxasset:// paths shipped with the engine), never an
-- unverifiable uploaded asset id.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)

local Feedback = {}

local SOUNDS = {
	buy = "rbxasset://sounds/electronicpingshort.wav",
	steal = "rbxasset://sounds/switch3.wav",
	rebirth = "rbxasset://sounds/uuhhh.mp3",
	wave = "rbxasset://sounds/impact_water.mp3",
	lock = "rbxasset://sounds/switch.wav",
}

-- The engine ships these; a missing one must never break feedback, so a failed load
-- just leaves the burst (which is already visible) and the sound is dropped.
local function playAt(parent, soundId, volume)
	if not parent then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.6
	sound.RollOffMaxDistance = 90
	sound.Parent = parent
	local ok = pcall(function()
		sound:Play()
	end)
	if not ok then
		sound:Destroy()
		return
	end
	Debris:AddItem(sound, 4)
end

local function burst(position, color, count)
	local anchor = Instance.new("Part")
	anchor.Name = "FxAnchor"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Position = position
	anchor.Parent = workspace
	Debris:AddItem(anchor, 2)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.7
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.4, 0.9)
	emitter.Speed = NumberRange.new(8, 18)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(count or 24)
end

local function localCharacterPosition()
	local character = game:GetService("Players").LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and root.Position
end

-- kind is "buy", "steal", "rebirth", "wave", "lock".
function Feedback.play(kind, worldPosition)
	local position = worldPosition or localCharacterPosition()
	if position then
		local color = Color3.fromRGB(255, 216, 96)
		if kind == "steal" then
			color = Color3.fromRGB(255, 112, 168)
		elseif kind == "rebirth" then
			color = Color3.fromRGB(150, 220, 255)
		elseif kind == "wave" then
			color = Color3.fromRGB(255, 96, 112)
		elseif kind == "lock" then
			color = Color3.fromRGB(120, 200, 255)
		end
		burst(position, color, kind == "rebirth" and 40 or 22)
	end
	local parent = workspace.CurrentCamera or workspace
	playAt(parent, SOUNDS[kind] or SOUNDS.buy, kind == "rebirth" and 0.8 or 0.5)
end

return Feedback
