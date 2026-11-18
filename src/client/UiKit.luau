-- Shared look for the client UI: palette, fonts, and small frame factories.

local Format = require(game:GetService("ReplicatedStorage").Shared.Format)

local UiKit = {}

UiKit.Theme = {
	panel = Color3.fromRGB(17, 19, 29),
	panelRaised = Color3.fromRGB(27, 30, 44),
	panelSoft = Color3.fromRGB(36, 40, 58),
	stroke = Color3.fromRGB(62, 68, 96),
	text = Color3.fromRGB(244, 246, 252),
	textDim = Color3.fromRGB(156, 164, 190),
	accent = Color3.fromRGB(120, 232, 255),
	money = Color3.fromRGB(130, 244, 162),
	warn = Color3.fromRGB(255, 196, 84),
	bad = Color3.fromRGB(255, 108, 132),
	good = Color3.fromRGB(120, 240, 156),
}

UiKit.Format = Format

function UiKit.corner(parent: Instance, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
	return corner
end

function UiKit.stroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or UiKit.Theme.stroke
	stroke.Thickness = thickness or 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

function UiKit.padding(parent: Instance, all: number): UIPadding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, all)
	padding.PaddingRight = UDim.new(0, all)
	padding.PaddingTop = UDim.new(0, all)
	padding.PaddingBottom = UDim.new(0, all)
	padding.Parent = parent
	return padding
end

function UiKit.panel(parent: Instance, name: string, size: UDim2, position: UDim2, anchor: Vector2?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = anchor or Vector2.zero
	frame.BackgroundColor3 = UiKit.Theme.panel
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = parent
	UiKit.corner(frame, 14)
	UiKit.stroke(frame)
	return frame
end

function UiKit.label(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, textSize: number?, color: Color3?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextSize = textSize or 16
	label.TextColor3 = color or UiKit.Theme.text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

function UiKit.button(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, color: Color3?): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color or UiKit.Theme.panelSoft
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextSize = 16
	button.TextColor3 = UiKit.Theme.text
	button.Parent = parent
	UiKit.corner(button, 10)
	UiKit.stroke(button, color and color:Lerp(Color3.new(1, 1, 1), 0.35) or UiKit.Theme.stroke, 1.5)
	return button
end

function UiKit.gradient(parent: Instance, top: Color3, bottom: Color3): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(top, bottom)
	gradient.Rotation = 90
	gradient.Parent = parent
	return gradient
end

return UiKit
