-- Feedback: player-facing confirmation that is not the hazard banner. Toasts
-- stack in the lower-middle for gameplay messages (bought, stole, locked,
-- out of money) and are explicitly never used for a passed wave — the banner
-- owns that moment. Also plays the particle burst on buy/steal/rebirth and a
-- small sound, using only Roblox's built-in library sounds (no asset ids).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Theme = require(script.Parent.Theme)

local Feedback = {}

local TOAST_LIFETIME = 3
local TOAST_LIMIT = 4

local gui
local toastHolder
local toasts = {}
local burstSound

local function trimToasts()
	while #toasts > TOAST_LIMIT do
		local oldest = table.remove(toasts, 1)
		if oldest then
			oldest:Destroy()
		end
	end
end

local function layoutToasts()
	for index, toast in ipairs(toasts) do
		local target = UDim2.new(0.5, 0, 1, -150 - (index - 1) * 34)
		TweenService:Create(toast, TweenInfo.new(0.18), { Position = target }):Play()
	end
end

function Feedback.toast(message: string, color: Color3?)
	if not toastHolder then
		return
	end
	local toast = Instance.new("Frame")
	toast.Name = "Toast"
	toast.Size = UDim2.fromOffset(360, 28)
	toast.Position = UDim2.new(0.5, 0, 1, -124)
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.BackgroundColor3 = Theme.Colors.panel
	toast.BackgroundTransparency = 0.06
	toast.BorderSizePixel = 0
	toast.Parent = toastHolder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Colors.stroke
	stroke.Thickness = 1
	stroke.Parent = toast

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.fromOffset(8, 0)
	label.BackgroundTransparency = 1
	label.Font = Theme.Font
	label.TextSize = 12
	label.TextColor3 = color or Theme.Colors.text
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = message
	label.Parent = toast

	table.insert(toasts, toast)
	trimToasts()
	layoutToasts()

	task.delay(TOAST_LIFETIME, function()
		for index, value in ipairs(toasts) do
			if value == toast then
				table.remove(toasts, index)
				break
			end
		end
		local fade = TweenService:Create(toast, TweenInfo.new(0.25), {
			BackgroundTransparency = 1,
			Position = toast.Position - UDim2.fromOffset(0, 10),
		})
		fade:Play()
		for _, child in ipairs(toast:GetDescendants()) do
			if child:IsA("TextLabel") then
				TweenService:Create(child, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
			elseif child:IsA("UIStroke") and child.Name ~= "Ignore" then
				TweenService:Create(child, TweenInfo.new(0.25), { Transparency = 1 }):Play()
			end
		end
		Debris:AddItem(toast, 0.35)
		layoutToasts()
	end)
end

--- A puff of particles at the player's character, coloured per event.
function Feedback.burst(kind: string, label: string?)
	local character = Players.LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local colors = {
		buy = Color3.fromRGB(124, 240, 158),
		steal = Color3.fromRGB(255, 196, 64),
		stolen = Color3.fromRGB(255, 92, 120),
		rebirth = Color3.fromRGB(178, 102, 255),
	}
	local color = colors[kind] or Theme.Colors.income

	local emitterPart = Instance.new("Part")
	emitterPart.Name = "BurstEmitter"
	emitterPart.Size = Vector3.new(1, 1, 1)
	emitterPart.Transparency = 1
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.CanQuery = false
	emitterPart.Position = hrp.Position
	emitterPart.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.3))
	emitter.LightEmission = 0.7
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Speed = NumberRange.new(14, 26)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = emitterPart
	emitter:Emit(36)

	if burstSound then
		local sound = burstSound:Clone()
		sound.Parent = emitterPart
		sound:Play()
	end

	Debris:AddItem(emitterPart, 1.2)

	if label and label ~= "" then
		Feedback.toast(label, color)
	end
end

function Feedback.init()
	local player = Players.LocalPlayer
	gui = player:WaitForChild("PlayerGui")

	toastHolder = Instance.new("Frame")
	toastHolder.Name = "ToastHolder"
	toastHolder.BackgroundTransparency = 1
	toastHolder.Size = UDim2.fromScale(1, 1)
	toastHolder.ZIndex = 2
	toastHolder.Parent = gui

	-- Roblox built-in library sound (no unverifiable asset ids).
	burstSound = Instance.new("Sound")
	burstSound.Name = "Pickup"
	burstSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	burstSound.Volume = 0.35
	burstSound.PlaybackSpeed = 1.15
end

function Feedback.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local notice = remotes:WaitForChild("Notice")
	local burst = remotes:WaitForChild("EffectBurst")

	notice.OnClientEvent:Connect(function(message)
		Feedback.toast(message, Theme.Colors.text)
	end)

	burst.OnClientEvent:Connect(function(kind, label)
		Feedback.burst(kind, nil)
		local colors = {
			buy = Theme.Colors.ok,
			steal = Theme.Colors.warning,
			stolen = Theme.Colors.danger,
			rebirth = Theme.Rarity.Epic,
		}
		Feedback.toast(label or kind, colors[kind] or Theme.Colors.text)
	end)
end

return Feedback
