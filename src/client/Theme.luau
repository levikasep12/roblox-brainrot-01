-- Theme: shared look for every client surface. One palette and a few helpers
-- (rounded panel, label) so the HUD, shop and banner read as one product and a
-- colour change happens in one file.

local Theme = {}

Theme.Colors = {
	ink = Color3.fromRGB(12, 14, 22),
	panel = Color3.fromRGB(18, 21, 32),
	panelSoft = Color3.fromRGB(26, 30, 44),
	stroke = Color3.fromRGB(58, 66, 90),
	text = Color3.fromRGB(238, 242, 250),
	dim = Color3.fromRGB(150, 160, 184),
	money = Color3.fromRGB(124, 240, 158),
	income = Color3.fromRGB(126, 226, 255),
	accent = Color3.fromRGB(255, 96, 176),
	warning = Color3.fromRGB(255, 196, 64),
	danger = Color3.fromRGB(255, 92, 120),
	ok = Color3.fromRGB(120, 236, 160),
	x2 = Color3.fromRGB(255, 214, 64),
}

Theme.Rarity = {
	Common = Color3.fromRGB(176, 190, 197),
	Rare = Color3.fromRGB(86, 156, 255),
	Epic = Color3.fromRGB(178, 102, 255),
	Legendary = Color3.fromRGB(255, 176, 32),
	Mythic = Color3.fromRGB(255, 84, 144),
}

Theme.Font = Enum.Font.GothamMedium
Theme.FontBold = Enum.Font.GothamBold
Theme.FontBlack = Enum.Font.GothamBlack

function Theme.panel(parent: Instance, name: string, size: UDim2, position: UDim2, anchor: Vector2?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	if anchor then
		frame.AnchorPoint = anchor
	end
	frame.BackgroundColor3 = Theme.Colors.panel
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.stroke
	stroke.Thickness = 1
	stroke.Transparency = 0.35
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = frame

	return frame
end

function Theme.label(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, textSize: number?, color: Color3?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Theme.Font
	label.TextSize = textSize or 14
	label.TextColor3 = color or Theme.Colors.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

function Theme.button(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, color: Color3?): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Size = size
	button.Position = position
	button.AutoButtonColor = true
	button.BackgroundColor3 = color or Theme.Colors.panelSoft
	button.BorderSizePixel = 0
	button.Font = Theme.FontBold
	button.TextSize = 13
	button.TextColor3 = Theme.Colors.text
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.stroke
	stroke.Thickness = 1
	stroke.Transparency = 0.3
	stroke.Parent = button

	return button
end

function Theme.formatMoney(amount: number): string
	local rounded = math.floor(amount)
	if rounded >= 1_000_000 then
		return ("$%.2fM"):format(rounded / 1_000_000)
	elseif rounded >= 10_000 then
		return ("$%.1fK"):format(rounded / 1000)
	end
	local text = tostring(rounded)
	local out = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return "$" .. out
end

return Theme
