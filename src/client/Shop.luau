-- The shop panel: one card per brainrot currently walking the conveyor, with
-- its name, rarity, $/s and price, and a Buy button that calls the server.
-- Open with B or the shop prompt; close with the X, Escape or B again.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared.Format)
local BrainrotDefs = require(Shared.BrainrotDefs)

local Shop = {}

local THEME = {
	panel = Color3.fromRGB(18, 19, 30),
	card = Color3.fromRGB(30, 32, 48),
	cardHot = Color3.fromRGB(42, 46, 68),
	text = Color3.fromRGB(238, 240, 250),
	dim = Color3.fromRGB(150, 156, 176),
	money = Color3.fromRGB(126, 255, 173),
}

-- A miniature rarity chip "COMMON" / "MYTHIC" tinted with the rarity colour.
local function rarityChip(parent, rarity)
	local color = BrainrotDefs.RarityColor[rarity] or Color3.fromRGB(220, 220, 220)
	local chip = Instance.new("TextLabel")
	chip.Name = "Rarity"
	chip.Size = UDim2.fromOffset(84, 20)
	chip.BackgroundColor3 = color
	chip.BackgroundTransparency = 0.82
	chip.BorderSizePixel = 0
	chip.Font = Enum.Font.GothamBold
	chip.TextSize = 11
	chip.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.4)
	chip.Text = string.upper(rarity)
	chip.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = chip
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1
	stroke.Transparency = 0.4
	stroke.Parent = chip
	return chip
end

function Shop.Create(playerGui, callbacks)
	local root = Instance.new("ScreenGui")
	root.Name = "BrainrotShop"
	root.ResetOnSpawn = false
	root.IgnoreGuiInset = true
	root.DisplayOrder = 8
	root.Enabled = false
	root.Parent = playerGui

	local overlay = Instance.new("TextButton")
	overlay.Name = "Scrim"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(6, 6, 12)
	overlay.BackgroundTransparency = 0.45
	overlay.AutoButtonColor = false
	overlay.Text = ""
	overlay.BorderSizePixel = 0
	overlay.Parent = root

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(720, 470)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = THEME.panel
	panel.BorderSizePixel = 0
	panel.Parent = root
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(84, 92, 130)
	stroke.Thickness = 2
	stroke.Parent = panel

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -100, 0, 52)
	header.Position = UDim2.fromOffset(24, 12)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBlack
	header.TextSize = 30
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = Color3.fromRGB(255, 226, 150)
	header.Text = "BRAINROT SHOP"
	header.Parent = panel

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Size = UDim2.new(1, -100, 0, 20)
	sub.Position = UDim2.fromOffset(26, 60)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamSemibold
	sub.TextSize = 13
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.TextColor3 = THEME.dim
	sub.Text = "Buy the next tier off the conveyor. Higher rarity, faster money."
	sub.Parent = panel

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Size = UDim2.fromOffset(38, 38)
	close.Position = UDim2.new(1, -50, 0, 14)
	close.BackgroundColor3 = Color3.fromRGB(52, 40, 56)
	close.BorderSizePixel = 0
	close.Font = Enum.Font.GothamBlack
	close.TextSize = 20
	close.TextColor3 = Color3.fromRGB(255, 180, 190)
	close.Text = "X"
	close.Parent = panel
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 9)
	closeCorner.Parent = close

	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "Money"
	moneyLabel.Size = UDim2.fromOffset(320, 28)
	moneyLabel.Position = UDim2.fromOffset(26, 82)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Font = Enum.Font.GothamBold
	moneyLabel.TextSize = 20
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.TextColor3 = THEME.money
	moneyLabel.Text = "$0"
	moneyLabel.Parent = panel

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Cards"
	scroll.Size = UDim2.new(1, -40, 1, -134)
	scroll.Position = UDim2.fromOffset(20, 116)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(96, 104, 140)
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = panel
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(214, 128)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll

	local handle = {
		root = root,
		open = false,
	}

	function handle.SetOpen(open)
		handle.open = open
		root.Enabled = open
		if open then
			panel.Size = UDim2.fromOffset(680, 430)
			TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(720, 470),
			}):Play()
		end
	end

	function handle.Toggle()
		handle.SetOpen(not handle.open)
	end

	local order = 0
	local lastSignature = nil

	-- Rebuilt only when the offer list or the player's affordability changes.
	-- The server pushes a snapshot several times a second, and destroying and
	-- recreating every card at that rate would fight the player's clicks.
	function handle.Render(offers, money)
		local signature = {}
		for _, offer in ipairs(offers) do
			table.insert(signature, table.concat({ offer.id, offer.mutation or "-", math.floor(offer.price) }, "|"))
		end
		local affordableMask = {}
		for _, offer in ipairs(offers) do
			table.insert(affordableMask, money >= offer.price and "1" or "0")
		end
		local sig = table.concat(signature, ",") .. "#" .. table.concat(affordableMask, "")
		if sig == lastSignature then
			moneyLabel.Text = "You have " .. Format.Money(money)
			return
		end
		lastSignature = sig
		moneyLabel.Text = "You have " .. Format.Money(money)

		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextButton") then
				child:Destroy()
			end
		end
		order = 0
		if #offers == 0 then
			local empty = Instance.new("TextLabel")
			empty.Name = "Empty"
			empty.Size = UDim2.new(1, -20, 0, 60)
			empty.Position = UDim2.fromOffset(10, 20)
			empty.BackgroundTransparency = 1
			empty.Font = Enum.Font.GothamSemibold
			empty.TextSize = 16
			empty.TextColor3 = THEME.dim
			empty.Text = "Nothing on the belt right now. Watch the conveyor."
			empty.Parent = scroll
			return
		end

		for _, offer in ipairs(offers) do
			order += 1
			local affordable = money >= offer.price
			local card = Instance.new("TextButton")
			card.Name = "Offer" .. offer.id
			card.BackgroundColor3 = THEME.card
			card.AutoButtonColor = false
			card.BorderSizePixel = 0
			card.Text = ""
			card.LayoutOrder = order
			card.Parent = scroll
			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 12)
			cardCorner.Parent = card
			local cardStroke = Instance.new("UIStroke")
			cardStroke.Color = BrainrotDefs.RarityColor[offer.rarity] or Color3.fromRGB(220, 220, 220)
			cardStroke.Thickness = 1.5
			cardStroke.Transparency = 0.35
			cardStroke.Parent = card

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "Name"
			nameLabel.Size = UDim2.new(1, -16, 0, 22)
			nameLabel.Position = UDim2.fromOffset(10, 8)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 15
			nameLabel.TextScaled = true
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextColor3 = THEME.text
			nameLabel.Text = offer.name
			nameLabel.Parent = card

			local chip = rarityChip(card, offer.rarity)
			chip.Position = UDim2.fromOffset(10, 34)

			local mutationLabel = Instance.new("TextLabel")
			mutationLabel.Name = "Mutation"
			mutationLabel.Size = UDim2.fromOffset(96, 20)
			mutationLabel.Position = UDim2.fromOffset(100, 34)
			mutationLabel.BackgroundTransparency = 1
			mutationLabel.Font = Enum.Font.GothamBold
			mutationLabel.TextSize = 11
			mutationLabel.TextXAlignment = Enum.TextXAlignment.Right
			if offer.mutation then
				local info = BrainrotDefs.Mutations[offer.mutation]
				mutationLabel.Text = string.upper(offer.mutation)
				mutationLabel.TextColor3 = info.sparkle
			else
				mutationLabel.Text = ""
			end
			mutationLabel.Parent = card

			local rateLabel = Instance.new("TextLabel")
			rateLabel.Name = "Rate"
			rateLabel.Size = UDim2.new(1, -20, 0, 20)
			rateLabel.Position = UDim2.fromOffset(10, 58)
			rateLabel.BackgroundTransparency = 1
			rateLabel.Font = Enum.Font.GothamSemibold
			rateLabel.TextSize = 14
			rateLabel.TextXAlignment = Enum.TextXAlignment.Left
			rateLabel.TextColor3 = Color3.fromRGB(150, 246, 190)
			rateLabel.Text = Format.Rate(offer.rate) .. "  income"
			rateLabel.Parent = card

			local buy = Instance.new("TextButton")
			buy.Name = "Buy"
			buy.Size = UDim2.new(1, -20, 0, 30)
			buy.Position = UDim2.new(0, 10, 1, -38)
			buy.BackgroundColor3 = affordable and Color3.fromRGB(56, 168, 112) or Color3.fromRGB(58, 62, 82)
			buy.BorderSizePixel = 0
			buy.Font = Enum.Font.GothamBold
			buy.TextSize = 15
			buy.TextColor3 = affordable and Color3.fromRGB(240, 255, 246) or THEME.dim
			buy.Text = (affordable and "BUY  " or "NEED  ") .. Format.Money(offer.price)
			buy.Parent = card
			local buyCorner = Instance.new("UICorner")
			buyCorner.CornerRadius = UDim.new(0, 8)
			buyCorner.Parent = buy

			buy.Activated:Connect(function()
				if not affordable then
					callbacks.toast("Not enough money for " .. offer.name, Color3.fromRGB(255, 160, 160))
					return
				end
				buy.Text = "BUYING..."
				local ok, message = callbacks.buy(offer.id)
				callbacks.toast(message or (offer.name .. " bought"), ok and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(255, 160, 160))
				if ok then
					callbacks.burst()
				end
			end)
		end
	end

	close.Activated:Connect(function()
		handle.SetOpen(false)
	end)
	overlay.Activated:Connect(function()
		handle.SetOpen(false)
	end)

	return handle
end

return Shop
