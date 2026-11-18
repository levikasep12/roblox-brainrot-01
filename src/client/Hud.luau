-- The heads-up display: money with a tweened tick, income, multiplier,
-- rebirth and lock buttons, a hazard banner and a toast feed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local UiKit = require(script.Parent.UiKit)
local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local Hud = {}

local theme = UiKit.Theme

local root: ScreenGui
local widgets = {}

local displayedMoney = 0
local targetMoney = 0
local moneyPulse = 0

function Hud.build(playerGui: PlayerGui)
	root = Instance.new("ScreenGui")
	root.Name = "BrainrotHud"
	root.ResetOnSpawn = false
	root.IgnoreGuiInset = false
	root.DisplayOrder = 10
	root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local statusCard = UiKit.panel(root, "StatusCard", UDim2.fromOffset(300, 118), UDim2.fromOffset(18, 18))
	UiKit.gradient(statusCard, Color3.fromRGB(24, 27, 42), Color3.fromRGB(14, 16, 26))

	UiKit.label(statusCard, "GameTitle", "BRAINROT RUSH", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(14, 8), 13, theme.accent)
	local titleAccent = Instance.new("Frame")
	titleAccent.Name = "TitleAccent"
	titleAccent.Size = UDim2.fromOffset(52, 2)
	titleAccent.Position = UDim2.fromOffset(14, 30)
	titleAccent.BackgroundColor3 = theme.accent
	titleAccent.BorderSizePixel = 0
	titleAccent.Parent = statusCard

	local moneyLabel = UiKit.label(statusCard, "Money", "$0", UDim2.new(1, -24, 0, 42), UDim2.fromOffset(14, 34), 34, theme.money)
	widgets.money = moneyLabel

	local incomeLabel = UiKit.label(statusCard, "Income", "+$0/s", UDim2.new(0.55, 0, 0, 20), UDim2.fromOffset(14, 79), 15, theme.good)
	widgets.income = incomeLabel

	local multiplierLabel = UiKit.label(statusCard, "Multiplier", "x1.00", UDim2.new(0.45, -14, 0, 20), UDim2.new(0.55, 0, 0, 79), 15, theme.warn)
	multiplierLabel.TextXAlignment = Enum.TextXAlignment.Right
	widgets.multiplier = multiplierLabel

	local baseLabel = UiKit.label(statusCard, "BaseLabel", "Plot -", UDim2.new(0.5, -14, 0, 18), UDim2.fromOffset(14, 97), 12, theme.textDim)
	widgets.base = baseLabel

	local slotLabel = UiKit.label(statusCard, "SlotLabel", "0/6 slots", UDim2.new(0.5, -14, 0, 18), UDim2.new(0.5, 0, 0, 97), 12, theme.textDim)
	slotLabel.TextXAlignment = Enum.TextXAlignment.Right
	widgets.slots = slotLabel

	local actionBar = Instance.new("Frame")
	actionBar.Name = "ActionBar"
	actionBar.AnchorPoint = Vector2.new(0.5, 1)
	actionBar.Position = UDim2.new(0.5, 0, 1, -18)
	actionBar.Size = UDim2.fromOffset(560, 66)
	actionBar.BackgroundTransparency = 1
	actionBar.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = actionBar

	local lockButton = UiKit.button(actionBar, "LockButton", "LOCK BASE  $350", UDim2.fromOffset(170, 52), UDim2.fromOffset(0, 0), Color3.fromRGB(38, 84, 76))
	lockButton.LayoutOrder = 1
	widgets.lock = lockButton
	UiKit.label(lockButton, "Sub", "L  key", UDim2.new(1, 0, 0, 14), UDim2.new(0, 0, 1, -16), 11, theme.textDim).TextXAlignment = Enum.TextXAlignment.Center

	local stealButton = UiKit.button(actionBar, "StealButton", "STEAL  [F]", UDim2.fromOffset(150, 52), UDim2.fromOffset(0, 0), Color3.fromRGB(96, 48, 66))
	stealButton.LayoutOrder = 2
	widgets.steal = stealButton

	local dashButton = UiKit.button(actionBar, "DashButton", "DASH HOME  [Q]", UDim2.fromOffset(170, 52), UDim2.fromOffset(0, 0), Color3.fromRGB(44, 56, 104))
	dashButton.LayoutOrder = 3
	widgets.dash = dashButton

	local rebirthPanel = UiKit.panel(root, "RebirthPanel", UDim2.fromOffset(250, 96), UDim2.new(1, -18, 0, 18), Vector2.new(1, 0))
	UiKit.gradient(rebirthPanel, Color3.fromRGB(40, 32, 66), Color3.fromRGB(20, 18, 32))
	UiKit.label(rebirthPanel, "Title", "REBIRTH", UDim2.new(1, -24, 0, 18), UDim2.fromOffset(14, 8), 13, Color3.fromRGB(198, 172, 255))
	local rebirthInfo = UiKit.label(rebirthPanel, "Info", "x1.00 -> x1.25", UDim2.new(1, -24, 0, 16), UDim2.fromOffset(14, 26), 12, theme.textDim)
	widgets.rebirthInfo = rebirthInfo
	local rebirthButton = UiKit.button(rebirthPanel, "RebirthButton", "REBIRTH  $1.2K", UDim2.new(1, -28, 0, 40), UDim2.fromOffset(14, 46), Color3.fromRGB(96, 72, 168))
	rebirthButton.TextSize = 15
	widgets.rebirth = rebirthButton
	UiKit.label(rebirthButton, "Sub", "R  key", UDim2.new(1, 0, 0, 12), UDim2.new(0, 0, 1, -14), 10, Color3.fromRGB(214, 202, 240)).TextXAlignment = Enum.TextXAlignment.Center

	local hazardBanner = Instance.new("Frame")
	hazardBanner.Name = "HazardBanner"
	hazardBanner.AnchorPoint = Vector2.new(0.5, 0)
	hazardBanner.Position = UDim2.new(0.5, 0, 0, 14)
	hazardBanner.Size = UDim2.fromOffset(460, 46)
	hazardBanner.BackgroundColor3 = Color3.fromRGB(96, 30, 48)
	hazardBanner.BackgroundTransparency = 0
	hazardBanner.BorderSizePixel = 0
	hazardBanner.Visible = false
	hazardBanner.Parent = root
	UiKit.corner(hazardBanner, 12)
	UiKit.stroke(hazardBanner, theme.bad, 2)
	local hazardLabel = UiKit.label(hazardBanner, "HazardText", "HAZARD WAVE", UDim2.new(1, -24, 1, 0), UDim2.fromOffset(12, 0), 17, Color3.fromRGB(255, 230, 236))
	hazardLabel.TextXAlignment = Enum.TextXAlignment.Center
	widgets.hazardBanner = hazardBanner
	widgets.hazardText = hazardLabel

	local toastColumn = Instance.new("Frame")
	toastColumn.Name = "Toasts"
	toastColumn.AnchorPoint = Vector2.new(0, 1)
	toastColumn.Position = UDim2.new(0, 18, 1, -96)
	toastColumn.Size = UDim2.fromOffset(330, 250)
	toastColumn.BackgroundTransparency = 1
	toastColumn.Parent = root
	local toastLayout = Instance.new("UIListLayout")
	toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	toastLayout.Padding = UDim.new(0, 6)
	toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
	toastLayout.Parent = toastColumn
	widgets.toastColumn = toastColumn
	widgets.toastLayout = toastLayout

	local hintCard = UiKit.panel(root, "HintCard", UDim2.fromOffset(292, 74), UDim2.new(1, -18, 1, -104), Vector2.new(1, 1))
	hintCard.BackgroundTransparency = 0.25
	UiKit.label(hintCard, "Title", "HOW TO PLAY", UDim2.new(1, -24, 0, 16), UDim2.fromOffset(14, 8), 12, theme.accent)
	UiKit.label(hintCard, "Line1", "Walk the belt and press E near a brainrot", UDim2.new(1, -24, 0, 14), UDim2.fromOffset(14, 26), 11, theme.textDim)
	UiKit.label(hintCard, "Line2", "Q dash home  -  L lock  -  F steal in reach", UDim2.new(1, -24, 0, 14), UDim2.fromOffset(14, 42), 11, theme.textDim)
	UiKit.label(hintCard, "Line3", "Open a brainrot on a base to steal it", UDim2.new(1, -24, 0, 14), UDim2.fromOffset(14, 56), 11, theme.textDim)

	root.Parent = playerGui

	RunService.RenderStepped:Connect(function(dt)
		local difference = targetMoney - displayedMoney
		if math.abs(difference) > 0.01 then
			displayedMoney += difference * math.min(1, dt * 9)
			moneyPulse = math.min(1, moneyPulse + dt * 2)
			moneyLabel.Text = Format.money(displayedMoney)
		else
			displayedMoney = targetMoney
			moneyLabel.Text = Format.money(displayedMoney)
			moneyPulse = math.max(0, moneyPulse - dt * 3)
		end
		local scale = 1 + moneyPulse * 0.05
		moneyLabel.TextSize = math.floor(34 * scale)
		moneyLabel.TextColor3 = theme.money:Lerp(Color3.fromRGB(255, 255, 255), moneyPulse * 0.35)
	end)

	return widgets
end

function Hud.setMoney(amount: number)
	targetMoney = amount
end

function Hud.setIncome(rate: number)
	widgets.income.Text = Format.rate(rate)
end

function Hud.setMultiplier(multiplier: number)
	widgets.multiplier.Text = string.format("x%.2f", multiplier)
end

function Hud.setBase(plotIndex: number, slotCount: number)
	widgets.base.Text = if plotIndex > 0 then "PLOT " .. plotIndex else "SPECTATING"
	widgets.slots.Text = slotCount .. "/" .. GameConfig.StartingSlots .. " slots"
end

function Hud.setRebirth(rebirths: number, cost: number, multiplier: number, canAfford: boolean, maxed: boolean)
	if maxed then
		widgets.rebirth.Text = "MAX REBIRTHS"
		widgets.rebirthInfo.Text = "Multiplier x" .. string.format("%.2f", multiplier)
		widgets.rebirth.BackgroundColor3 = Color3.fromRGB(56, 52, 70)
		return
	end
	widgets.rebirth.Text = "REBIRTH  " .. Format.money(cost)
	widgets.rebirthInfo.Text = string.format("x%.2f -> x%.2f  (%d done)", multiplier, 1 + (rebirths + 1) * GameConfig.Rebirth.multiplierPerRebirth, rebirths)
	widgets.rebirth.BackgroundColor3 = if canAfford then Color3.fromRGB(112, 80, 190) else Color3.fromRGB(64, 56, 92)
end

function Hud.setLock(active: boolean, remaining: number, cost: number)
	if active then
		widgets.lock.Text = "LOCKED  " .. Format.clock(remaining)
		widgets.lock.BackgroundColor3 = Color3.fromRGB(34, 108, 86)
	else
		widgets.lock.Text = "LOCK BASE  " .. Format.money(cost)
		widgets.lock.BackgroundColor3 = Color3.fromRGB(38, 84, 76)
	end
end

function Hud.setSteal(ready: boolean, remaining: number)
	if ready then
		widgets.steal.Text = "STEAL  [F]"
		widgets.steal.BackgroundColor3 = Color3.fromRGB(120, 54, 78)
	else
		widgets.steal.Text = "STEAL  " .. string.format("%.1fs", remaining)
		widgets.steal.BackgroundColor3 = Color3.fromRGB(74, 48, 58)
	end
end

function Hud.setDash(dashing: boolean, remaining: number)
	if dashing then
		widgets.dash.Text = "DASHING!"
		widgets.dash.BackgroundColor3 = Color3.fromRGB(72, 96, 168)
	elseif remaining > 0 then
		widgets.dash.Text = "DASH  " .. string.format("%.0fs", remaining)
		widgets.dash.BackgroundColor3 = Color3.fromRGB(42, 50, 80)
	else
		widgets.dash.Text = "DASH HOME  [Q]"
		widgets.dash.BackgroundColor3 = Color3.fromRGB(44, 56, 104)
	end
end

function Hud.setHazard(phase: string, secondsLeft: number)
	local banner = widgets.hazardBanner
	if phase == "warning" then
		banner.Visible = true
		widgets.hazardText.Text = string.format("HAZARD WAVE IN %.1fs - GET HOME", secondsLeft)
		banner.BackgroundColor3 = Color3.fromRGB(120, 36, 56)
	elseif phase == "sweeping" then
		banner.Visible = true
		widgets.hazardText.Text = "WAVE SWEEPING - DASH HOME NOW"
		banner.BackgroundColor3 = Color3.fromRGB(150, 40, 62)
	elseif phase == "cooldown" then
		banner.Visible = true
		widgets.hazardText.Text = "WAVE PASSED - INCOME x2"
		banner.BackgroundColor3 = Color3.fromRGB(36, 96, 74)
	else
		banner.Visible = false
	end
end

function Hud.toast(message: string, tone: string)
	local column = widgets.toastColumn
	local card = Instance.new("Frame")
	card.Size = UDim2.fromOffset(330, 34)
	card.BackgroundColor3 = if tone == "good"
		then Color3.fromRGB(30, 66, 48)
		elseif tone == "bad" then Color3.fromRGB(78, 30, 42)
		elseif tone == "warn" then Color3.fromRGB(84, 64, 26)
		else Color3.fromRGB(30, 34, 50)
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.Parent = column
	UiKit.corner(card, 8)
	UiKit.stroke(card, Color3.fromRGB(255, 255, 255), 1)
	card:FindFirstChildOfClass("UIStroke").Transparency = 0.85
	card.LayoutOrder = tick()
	local label = UiKit.label(card, "Text", message, UDim2.new(1, -20, 1, 0), UDim2.fromOffset(10, 0), 13)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd

	local tween = TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
	local labelTween = TweenService:Create(label, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { TextTransparency = 1 })

	task.delay(3.4, function()
		tween:Play()
		labelTween:Play()
		task.wait(0.3)
		card:Destroy()
	end)

	while #column:GetChildren() > 8 do
		local oldest = nil
		for _, child in ipairs(column:GetChildren()) do
			if child:IsA("Frame") then
				if not oldest or child.LayoutOrder < oldest.LayoutOrder then
					oldest = child
				end
			end
		end
		if oldest then
			oldest:Destroy()
		else
			break
		end
	end
end

return Hud
