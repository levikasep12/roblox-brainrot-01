-- The shop panel: one card per brainrot the player can buy right now, with
-- rarity color, money-per-second and a buy button that fires the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiKit = require(script.Parent.UiKit)
local Format = require(ReplicatedStorage.Shared.Format)
local BrainrotDefs = require(ReplicatedStorage.Shared.BrainrotDefs)

local ShopUi = {}

local theme = UiKit.Theme
local panel: Frame
local listFrame: Frame
local toggleButton: TextButton
local open = false
local buyHandler: ((string) -> ())? = nil
local lastSignature = ""

function ShopUi.build(hudGui: ScreenGui)
	panel = UiKit.panel(hudGui, "ShopPanel", UDim2.fromOffset(360, 400), UDim2.fromOffset(18, 204))
	UiKit.gradient(panel, Color3.fromRGB(26, 30, 46), Color3.fromRGB(14, 16, 26))
	panel.Visible = false

	UiKit.label(panel, "Title", "BRAINROT EMPORIUM", UDim2.new(1, -28, 0, 22), UDim2.fromOffset(16, 12), 15, theme.accent)
	local subtitle = UiKit.label(panel, "Subtitle", "Golden 8.4%  |  Diamond 1.6% on the belt", UDim2.new(1, -28, 0, 16), UDim2.fromOffset(16, 34), 11, theme.textDim)
	subtitle.Name = "Subtitle"

	local close = UiKit.button(panel, "Close", "X", UDim2.fromOffset(28, 28), UDim2.new(1, -38, 0, 10), Color3.fromRGB(64, 32, 44))
	close.TextSize = 14

	listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "Cards"
	listFrame.Position = UDim2.fromOffset(14, 58)
	listFrame.Size = UDim2.new(1, -28, 1, -72)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 4
	listFrame.ScrollBarImageColor3 = theme.stroke
	listFrame.CanvasSize = UDim2.new()
	listFrame.Parent = panel
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listFrame

	toggleButton = UiKit.button(hudGui, "ShopToggle", "SHOP  [B]", UDim2.fromOffset(130, 44), UDim2.new(0, 18, 0, 150), Color3.fromRGB(44, 62, 96))

	local function toggle()
		open = not open
		panel.Visible = open
	end

	toggleButton.Activated:Connect(toggle)
	close.Activated:Connect(toggle)
	return {
		toggle = toggle,
		isOpen = function()
			return open
		end,
	}
end

function ShopUi.setBuyHandler(handler: (string) -> ())
	buyHandler = handler
end

function ShopUi.render(catalog, money: number)
	local signature = ""
	for _, item in ipairs(catalog) do
		local affordable = money >= item.price and "1" or "0"
		signature ..= item.defId .. ":" .. tostring(item.price) .. ":" .. affordable .. ";"
	end
	if signature == lastSignature then
		return
	end
	lastSignature = signature

	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for index, item in ipairs(catalog) do
		local rarityColor = BrainrotDefs.rarityColor(item.rarity)
		local card = Instance.new("Frame")
		card.Name = item.defId
		card.LayoutOrder = index
		card.Size = UDim2.new(1, -6, 0, 76)
		card.BackgroundColor3 = Color3.fromRGB(24, 27, 40)
		card.BorderSizePixel = 0
		card.Parent = listFrame
		UiKit.corner(card, 10)
		UiKit.stroke(card, rarityColor, 1.5)

		local stripe = Instance.new("Frame")
		stripe.Name = "Stripe"
		stripe.Size = UDim2.fromOffset(5, 60)
		stripe.Position = UDim2.fromOffset(6, 8)
		stripe.BackgroundColor3 = rarityColor
		stripe.BorderSizePixel = 0
		stripe.Parent = card
		UiKit.corner(stripe, 3)

		UiKit.label(card, "Name", item.name, UDim2.new(1, -120, 0, 20), UDim2.fromOffset(20, 8), 15)
		UiKit.label(card, "Rarity", string.upper(item.rarity), UDim2.new(0, 90, 0, 16), UDim2.fromOffset(20, 28), 11, rarityColor)
		UiKit.label(card, "Rate", Format.rate(item.rate), UDim2.new(0, 140, 0, 18), UDim2.fromOffset(20, 46), 13, theme.good)
		local blurb = UiKit.label(card, "Blurb", item.blurb or "", UDim2.new(1, -24, 0, 14), UDim2.fromOffset(20, 62), 10, theme.textDim)
		blurb.TextTruncate = Enum.TextTruncate.AtEnd

		local canAfford = money >= item.price
		local buy = UiKit.button(
			card,
			"Buy",
			Format.money(item.price),
			UDim2.fromOffset(88, 34),
			UDim2.new(1, -96, 0, 14),
			if canAfford then Color3.fromRGB(44, 96, 68) else Color3.fromRGB(52, 54, 66)
		)
		buy.TextSize = 14
		buy.Activated:Connect(function()
			if buyHandler then
				buyHandler(item.defId)
			end
		end)
	end

	local layout = listFrame:FindFirstChildOfClass("UIListLayout")
	local count = 0
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") then
			count += 1
		end
	end
	listFrame.CanvasSize = UDim2.fromOffset(0, count * 84 + 8)
end

return ShopUi
