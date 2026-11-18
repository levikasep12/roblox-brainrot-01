-- ShopController: the buy panel. It lists every brainrot in BrainrotDefs with
-- its rarity, rate and price, greys out what the player cannot afford, and
-- highlights the shop's "next tier" — the cheapest one still unaffordable at
-- the top. Buying happens on the conveyor (press E), so the shop's rows act as
-- a catalogue plus a "walk to the conveyor" hint, keeping one economy path.
--
-- Toggle with B (or the SHOP button). The panel is keyboard-first because the
-- default camera scripts eat arrow keys; ContextActionService is used so the
-- bind survives the camera.

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))

local ShopController = {}

local frame
local rows = {}
local visible = false

local function refresh(state)
	local snapshot = state.snapshot
	if not snapshot then
		return
	end
	local money = snapshot.money or 0
	local nextTier
	for _, def in ipairs(BrainrotDefs.List) do
		if def.price > money then
			nextTier = def.id
			break
		end
	end
	for _, row in ipairs(rows) do
		local affordable = money >= row.def.price
		row.nameLabel.TextColor3 = affordable and Theme.Colors.text or Theme.Colors.dim
		row.priceLabel.TextColor3 = affordable and Theme.Colors.money or Theme.Colors.dim
		row.frame.BackgroundTransparency = (row.def.id == nextTier) and 0.0 or 0.55
		row.frame.BackgroundColor3 = (row.def.id == nextTier) and Color3.fromRGB(44, 38, 62) or Theme.Colors.panelSoft
		row.stroke.Color = Theme.Rarity[row.def.rarity] or Theme.Colors.stroke
		row.hit.AutoButtonColor = affordable
	end
end

local function buildRow(parent, def, index)
	local row = Instance.new("Frame")
	row.Name = def.id
	row.Size = UDim2.new(1, 0, 0, 42)
	row.Position = UDim2.fromOffset(0, (index - 1) * 46)
	row.BackgroundColor3 = Theme.Colors.panelSoft
	row.BackgroundTransparency = 0.55
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = row

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Rarity[def.rarity] or Theme.Colors.stroke
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = row

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.fromOffset(8, 30)
	swatch.Position = UDim2.fromOffset(6, 6)
	swatch.BackgroundColor3 = Theme.Rarity[def.rarity] or Theme.Colors.stroke
	swatch.BorderSizePixel = 0
	swatch.Parent = row
	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UDim.new(0, 4)
	swatchCorner.Parent = swatch

	local name = Theme.label(row, "Name", def.name, UDim2.new(1, -96, 0, 18), UDim2.fromOffset(20, 3), 12)
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Font = Theme.FontBold

	local meta = Theme.label(row, "Meta", ("%s · $%d/sec"):format(def.rarity, def.rate), UDim2.new(1, -96, 0, 14), UDim2.fromOffset(20, 22), 10, Theme.Rarity[def.rarity])
	local price = Theme.label(row, "Price", Theme.formatMoney(def.price), UDim2.fromOffset(78, 30), UDim2.new(1, -78, 0, 6), 13, Theme.Colors.money)
	price.Font = Theme.FontBold
	price.TextXAlignment = Enum.TextXAlignment.Right

	local hit = Instance.new("TextButton")
	hit.Name = "BuyHit"
	hit.Text = ""
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.fromScale(1, 1)
	hit.Parent = row
	hit.Activated:Connect(function()
		ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuyFromShop"):FireServer(def.id)
	end)

	rows[#rows + 1] = { frame = row, def = def, nameLabel = name, priceLabel = price, stroke = stroke, hit = hit }
end

local function toggle()
	visible = not visible
	frame.Visible = visible
end

function ShopController.build(state)
	local player = game:GetService("Players").LocalPlayer
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("BrainrotHud")

	frame = Instance.new("Frame")
	frame.Name = "ShopPanel"
	frame.Size = UDim2.fromOffset(330, 540)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Theme.Colors.panel
	frame.BackgroundTransparency = 0.04
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ZIndex = 5
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.stroke
	stroke.Thickness = 1
	stroke.Parent = frame

	local title = Theme.label(frame, "Title", "BRAINROT CATALOGUE", UDim2.new(1, -40, 0, 22), UDim2.fromOffset(14, 10), 15, Theme.Colors.text)
	title.Font = Theme.FontBlack

	local hint = Theme.label(frame, "Hint", "Click a row to buy it off the conveyor · B closes", UDim2.new(1, -28, 0, 16), UDim2.fromOffset(14, 32), 10, Theme.Colors.dim)

	local close = Theme.button(frame, "Close", "X", UDim2.fromOffset(28, 24), UDim2.new(1, -38, 0, 8), Color3.fromRGB(52, 28, 40))
	close.TextXAlignment = Enum.TextXAlignment.Center
	close.Activated:Connect(toggle)

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Rows"
	scroller.Size = UDim2.new(1, -24, 1, -64)
	scroller.Position = UDim2.fromOffset(12, 54)
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.ScrollBarThickness = 5
	scroller.CanvasSize = UDim2.fromOffset(0, #BrainrotDefs.List * 46 + 4)
	scroller.Parent = frame

	for index, def in ipairs(BrainrotDefs.List) do
		buildRow(scroller, def, index)
	end

	local open = Theme.button(gui, "ShopButton", "SHOP  (B)", UDim2.fromOffset(120, 32), UDim2.new(0.5, -60, 1, -46), Color3.fromRGB(52, 30, 54))
	open.ZIndex = 3
	open.Activated:Connect(toggle)

	state.onChange(function(kind)
		if kind == "state" then
			refresh(state.get())
		end
	end)

	ContextActionService:BindAction("ToggleBrainrotShop", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			toggle()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.B)

	local snapshot = state.get().snapshot
	if snapshot then
		refresh(state.get())
	end

	return frame
end

return ShopController
