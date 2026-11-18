-- The client HUD: money and income with tweened ticks, the persistent x2 badge, the
-- small hazard banner, rebirth/lock buttons, the shop panel and toasts. Rendering
-- only: it never changes game state, it asks the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)

local HUD = {}

local COLORS = {
	panel = Color3.fromRGB(18, 20, 30),
	panelSoft = Color3.fromRGB(28, 32, 46),
	text = Color3.fromRGB(238, 240, 248),
	muted = Color3.fromRGB(150, 158, 178),
	accent = Color3.fromRGB(255, 208, 84),
	green = Color3.fromRGB(108, 232, 148),
	danger = Color3.fromRGB(255, 92, 108),
	blue = Color3.fromRGB(112, 196, 255),
}

local function corner(instance, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = instance
	return c
end

local function stroke(instance, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(60, 66, 88)
	s.Thickness = thickness or 1.5
	s.Parent = instance
	return s
end

local function textLabel(parent, name, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextColor3 = color or COLORS.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = ""
	label.RichText = true
	label.Parent = parent
	return label
end

local function button(parent, name, size, position, text, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.TextColor3 = COLORS.panel
	b.Text = text
	b.Parent = parent
	corner(b, 7)
	return b
end

-- Builds every HUD element and returns the handle the client script drives.
function HUD.create(player)
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHUD"
	gui.ResetOnSpawn = false
	-- Respect the topbar inset so the hazard banner and money card are never hidden under it.
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = gui

	-- Top left: the money card with the persistent x2 badge beside the income.
	local card = Instance.new("Frame")
	card.Name = "MoneyCard"
	card.Position = UDim2.fromOffset(18, 18)
	card.Size = UDim2.fromOffset(268, 92)
	card.BackgroundColor3 = COLORS.panel
	card.BackgroundTransparency = 0.12
	card.BorderSizePixel = 0
	card.Parent = root
	corner(card, 10)
	stroke(card, Color3.fromRGB(70, 78, 108))

	local moneyLabel = textLabel(card, "Money", UDim2.new(1, -24, 0, 34), UDim2.fromOffset(14, 8), 28, COLORS.accent)
	moneyLabel.Text = "$0"

	local incomeLabel = textLabel(card, "Income", UDim2.new(1, -120, 0, 20), UDim2.fromOffset(15, 46), 14, COLORS.green)
	incomeLabel.Text = "+$0/s"

	local multLabel = textLabel(card, "Multiplier", UDim2.new(1, -24, 0, 18), UDim2.fromOffset(15, 66), 12, COLORS.muted)
	multLabel.Text = "x1.00 income  |  0 rebirths"

	local x2Badge = Instance.new("Frame")
	x2Badge.Name = "DoubleBadge"
	x2Badge.Position = UDim2.fromOffset(196, 44)
	x2Badge.Size = UDim2.fromOffset(58, 24)
	x2Badge.BackgroundColor3 = Color3.fromRGB(58, 34, 84)
	x2Badge.BorderSizePixel = 0
	x2Badge.Visible = false
	x2Badge.Parent = card
	corner(x2Badge, 12)
	stroke(x2Badge, Color3.fromRGB(190, 130, 255), 1.5)
	local x2Text = textLabel(x2Badge, "Double", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 13, Color3.fromRGB(220, 176, 255))
	x2Text.TextXAlignment = Enum.TextXAlignment.Center
	x2Text.Text = "x2"

	-- Top center: the small hazard banner. 380x36, text 13.
	local banner = Instance.new("TextLabel")
	banner.Name = "HazardBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 12)
	banner.Size = UDim2.fromOffset(380, 36)
	banner.BackgroundColor3 = Color3.fromRGB(32, 20, 30)
	banner.BackgroundTransparency = 0.1
	banner.BorderSizePixel = 0
	banner.Font = Enum.Font.GothamBold
	banner.TextSize = 13
	banner.TextColor3 = COLORS.danger
	banner.Text = ""
	banner.Visible = false
	banner.Parent = root
	corner(banner, 8)

	-- Bottom left: action buttons.
	local actions = Instance.new("Frame")
	actions.Name = "Actions"
	actions.AnchorPoint = Vector2.new(0, 1)
	actions.Position = UDim2.new(0, 18, 1, -18)
	actions.Size = UDim2.fromOffset(300, 88)
	actions.BackgroundTransparency = 1
	actions.Parent = root

	local rebirthButton = button(actions, "RebirthButton", UDim2.fromOffset(146, 40), UDim2.fromOffset(0, 0), "REBIRTH  [R]", COLORS.accent)
	local lockButton = button(actions, "LockButton", UDim2.fromOffset(146, 40), UDim2.fromOffset(154, 0), "LOCK BASE  [L]", COLORS.blue)
	local shopButton = button(actions, "ShopButton", UDim2.fromOffset(146, 40), UDim2.fromOffset(0, 44), "SHOP  [B]", COLORS.green)
	local hint = textLabel(actions, "Hint", UDim2.fromOffset(154, 40), UDim2.fromOffset(150, 46), 11, COLORS.muted)
	hint.Text = "Grab runway\nbrainrots!"

	-- Right side: the shop panel, hidden until opened.
	local shop = Instance.new("Frame")
	shop.Name = "Shop"
	shop.AnchorPoint = Vector2.new(1, 0)
	shop.Position = UDim2.new(1, -18, 0, 18)
	shop.Size = UDim2.fromOffset(296, 430)
	shop.BackgroundColor3 = COLORS.panel
	shop.BackgroundTransparency = 0.08
	shop.BorderSizePixel = 0
	shop.Visible = false
	shop.Parent = root
	corner(shop, 10)
	stroke(shop, Color3.fromRGB(70, 78, 108))

	local shopTitle = textLabel(shop, "Title", UDim2.new(1, -80, 0, 26), UDim2.fromOffset(14, 10), 15, COLORS.text)
	shopTitle.Text = "BRAINROT SHOP"
	local closeButton = button(shop, "Close", UDim2.fromOffset(28, 24), UDim2.new(1, -38, 0, 10), "X", COLORS.danger)
	closeButton.TextSize = 13

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "List"
	scroller.Position = UDim2.fromOffset(10, 42)
	scroller.Size = UDim2.new(1, -20, 1, -52)
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.ScrollBarThickness = 4
	scroller.ScrollBarImageColor3 = Color3.fromRGB(96, 104, 132)
	scroller.CanvasSize = UDim2.new()
	scroller.Parent = shop

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroller

	-- Bottom right: toast stack.
	local toasts = Instance.new("Frame")
	toasts.Name = "Toasts"
	toasts.AnchorPoint = Vector2.new(1, 1)
	toasts.Position = UDim2.new(1, -18, 1, -18)
	toasts.Size = UDim2.fromOffset(300, 140)
	toasts.BackgroundTransparency = 1
	toasts.Parent = root
	local toastLayout = Instance.new("UIListLayout")
	toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	toastLayout.Padding = UDim.new(0, 6)
	toastLayout.Parent = toasts

	return {
		gui = gui,
		root = root,
		moneyLabel = moneyLabel,
		incomeLabel = incomeLabel,
		multLabel = multLabel,
		x2Badge = x2Badge,
		banner = banner,
		rebirthButton = rebirthButton,
		lockButton = lockButton,
		shopButton = shopButton,
		shop = shop,
		shopList = scroller,
		closeShop = closeButton,
		toasts = toasts,
		displayedMoney = 0,
		bannerToken = 0,
		shopBuilt = false,
	}
end

-- Tweens the money number up (and down) instead of snapping, so income ticks visibly.
-- One persistent proxy is reused and its tween retargeted, so four state pushes a second
-- never pile up overlapping tweens or leak NumberValues.
function HUD.setMoney(hud, amount)
	if not hud.moneyProxy then
		local proxy = Instance.new("NumberValue")
		proxy.Name = "DisplayedMoney"
		proxy.Value = 0
		proxy.Parent = hud.gui
		proxy:GetPropertyChangedSignal("Value"):Connect(function()
			hud.moneyLabel.Text = "$" .. string.format("%d", math.floor(proxy.Value))
		end)
		hud.moneyProxy = proxy
	end
	local proxy = hud.moneyProxy
	if hud.moneyTween then
		hud.moneyTween:Cancel()
	end
	hud.displayedMoney = amount
	hud.moneyTween = TweenService:Create(
		proxy,
		TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = amount }
	)
	hud.moneyTween:Play()
end

function HUD.setIncome(hud, perSecond, multiplier, rebirths, doubled)
	hud.incomeLabel.Text = string.format("+$%d/s", math.floor(perSecond + 0.5))
	hud.multLabel.Text = string.format("x%.2f income  |  %d rebirths", multiplier, rebirths)
	hud.x2Badge.Visible = doubled == true
end

-- The hazard banner. Warning and sweeping stay up; the cooldown notice is transient.
function HUD.setBanner(hud, text, color, permanent)
	hud.bannerToken += 1
	local token = hud.bannerToken
	if text == nil or text == "" then
		hud.banner.Visible = false
		return
	end
	hud.banner.Text = text
	hud.banner.TextColor3 = color or COLORS.danger
	hud.banner.BackgroundColor3 = permanent and Color3.fromRGB(32, 20, 30) or Color3.fromRGB(26, 26, 40)
	hud.banner.Visible = true
	if not permanent then
		task.delay(2.5, function()
			if hud.bannerToken == token then
				hud.banner.Visible = false
			end
		end)
	end
end

local function addToast(hud, message, tone)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(300, 30)
	frame.BackgroundColor3 = tone == "danger" and Color3.fromRGB(66, 22, 30) or Color3.fromRGB(24, 30, 44)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = hud.toasts
	corner(frame, 6)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.fromOffset(8, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextColor3 = COLORS.text
	label.Text = message
	label.Parent = frame

	task.delay(3.2, function()
		local tween = TweenService:Create(frame, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
		tween:Play()
		TweenService:Create(label, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		task.wait(0.4)
		frame:Destroy()
	end)
end

HUD.addToast = addToast

-- The shop list: one row per brainrot, one button each, with a scroll in the panel.
function HUD.buildShop(hud, order)
	if hud.shopBuilt then
		return
	end
	hud.shopBuilt = true
	for index, item in ipairs(order) do
		local row = Instance.new("Frame")
		row.Name = item.id
		row.Size = UDim2.new(1, -6, 0, 54)
		row.BackgroundColor3 = COLORS.panelSoft
		row.BackgroundTransparency = 0.25
		row.BorderSizePixel = 0
		row.LayoutOrder = index
		row.Parent = hud.shopList
		corner(row, 7)

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 4, 1, 0)
		bar.BackgroundColor3 = BrainrotDefs.RarityColors[item.rarity] or COLORS.text
		bar.BorderSizePixel = 0
		bar.Parent = row
		corner(bar, 3)

		local name = textLabel(row, "Name", UDim2.new(1, -120, 0, 18), UDim2.fromOffset(12, 6), 13, COLORS.text)
		name.Text = item.name
		local detail = textLabel(row, "Detail", UDim2.new(1, -120, 0, 16), UDim2.fromOffset(12, 24), 11, COLORS.muted)
		detail.Text = string.format("%s  $%d/s", item.rarity, item.rate)

		local buy = button(row, "Buy", UDim2.fromOffset(86, 32), UDim2.new(1, -96, 0, 11), "$" .. item.price, COLORS.accent)
		buy.TextSize = 13
		buy.Name = "Buy_" .. item.id
	end
	hud.shopList.CanvasSize = UDim2.fromOffset(0, #order * 60)
end

return HUD
