-- The HUD: money with a visibly ticking counter, $/s, the rebirth multiplier
-- and level with a Rebirth button, the base lock button with its countdown,
-- a steal board of other plots, and a toast area for server messages.
-- Everything here is drawn over the 3D world; it never owns game state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared.Format)
local Config = require(Shared.Config)

local Hud = {}

local THEME = {
	panel = Color3.fromRGB(20, 21, 32),
	panelLight = Color3.fromRGB(32, 34, 50),
	accent = Color3.fromRGB(126, 246, 255),
	money = Color3.fromRGB(126, 255, 173),
	text = Color3.fromRGB(238, 240, 250),
	dim = Color3.fromRGB(150, 156, 176),
	danger = Color3.fromRGB(255, 118, 138),
}

Hud.ButtonColor = {
	rebirth = Color3.fromRGB(122, 84, 214),
	lock = Color3.fromRGB(48, 140, 190),
}

local function round(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function label(parent, props)
	local text = Instance.new("TextLabel")
	text.Name = props.name or "Label"
	text.BackgroundTransparency = 1
	text.Font = props.font or Enum.Font.GothamBold
	text.TextColor3 = props.color or THEME.text
	text.TextSize = props.size or 18
	text.TextXAlignment = props.align or Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Center
	text.Text = props.text or ""
	text.Size = props.sizeProp or UDim2.fromScale(1, 1)
	text.Position = props.position or UDim2.fromScale(0, 0)
	text.TextScaled = props.scaled or false
	text.RichText = props.rich or false
	text.Parent = parent
	return text
end

function Hud.CreateButton(parent, props)
	local button = Instance.new("TextButton")
	button.Name = props.name or "Button"
	button.Size = props.size or UDim2.fromOffset(150, 46)
	button.Position = props.position or UDim2.fromScale(0, 0)
	button.AnchorPoint = props.anchor or Vector2.zero
	button.BackgroundColor3 = props.color or THEME.panelLight
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = props.textSize or 18
	button.Text = props.text or "Button"
	button.BorderSizePixel = 0
	button.Parent = parent
	round(button, 10)
	stroke(button, (props.color or THEME.panelLight):Lerp(Color3.new(1, 1, 1), 0.3), 1.5)
	return button
end

-- Draws the HUD and returns a handle with its setters.
function Hud.Create(playerGui)
	local root = Instance.new("ScreenGui")
	root.Name = "BrainrotHud"
	root.ResetOnSpawn = false
	root.IgnoreGuiInset = true
	root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	root.DisplayOrder = 5
	root.Parent = playerGui

	-- Top-left: money and income.
	local moneyPanel = Instance.new("Frame")
	moneyPanel.Name = "MoneyPanel"
	moneyPanel.Size = UDim2.fromOffset(340, 118)
	moneyPanel.Position = UDim2.fromOffset(18, 18)
	moneyPanel.BackgroundColor3 = THEME.panel
	moneyPanel.BackgroundTransparency = 0.08
	moneyPanel.BorderSizePixel = 0
	moneyPanel.Parent = root
	round(moneyPanel, 14)
	stroke(moneyPanel, Color3.fromRGB(70, 78, 108), 2)

	local moneyLabel = label(moneyPanel, {
		name = "Money",
		text = "$0",
		size = 46,
		position = UDim2.fromOffset(16, 8),
		sizeProp = UDim2.fromOffset(300, 54),
		color = THEME.money,
	})
	moneyLabel.Name = "Money"

	local incomeLabel = label(moneyPanel, {
		text = "$0/s",
		size = 20,
		position = UDim2.fromOffset(18, 62),
		sizeProp = UDim2.fromOffset(200, 24),
		color = Color3.fromRGB(168, 246, 200),
	})
	incomeLabel.Name = "Income"

	local multBadge = Instance.new("TextLabel")
	multBadge.Name = "Multiplier"
	multBadge.Size = UDim2.fromOffset(150, 30)
	multBadge.Position = UDim2.fromOffset(18, 86)
	multBadge.BackgroundColor3 = Color3.fromRGB(44, 38, 74)
	multBadge.BorderSizePixel = 0
	multBadge.Font = Enum.Font.GothamBold
	multBadge.TextSize = 15
	multBadge.TextColor3 = Color3.fromRGB(214, 190, 255)
	multBadge.Text = "x1.0 MULT"
	multBadge.Parent = moneyPanel
	round(multBadge, 8)

	local rebirthBadge = Instance.new("TextLabel")
	rebirthBadge.Name = "RebirthLevel"
	rebirthBadge.Size = UDim2.fromOffset(140, 30)
	rebirthBadge.Position = UDim2.fromOffset(178, 86)
	rebirthBadge.BackgroundTransparency = 1
	rebirthBadge.Font = Enum.Font.GothamSemibold
	rebirthBadge.TextSize = 14
	rebirthBadge.TextXAlignment = Enum.TextXAlignment.Right
	rebirthBadge.TextColor3 = THEME.dim
	rebirthBadge.Text = "REBIRTH 0"
	rebirthBadge.Parent = moneyPanel

	-- Top-right: the action buttons.
	local actionPanel = Instance.new("Frame")
	actionPanel.Name = "Actions"
	actionPanel.Size = UDim2.fromOffset(232, 152)
	actionPanel.Position = UDim2.new(1, -18, 0, 18)
	actionPanel.AnchorPoint = Vector2.new(1, 0)
	actionPanel.BackgroundColor3 = THEME.panel
	actionPanel.BackgroundTransparency = 0.08
	actionPanel.BorderSizePixel = 0
	actionPanel.Parent = root
	round(actionPanel, 14)
	stroke(actionPanel, Color3.fromRGB(70, 78, 108), 2)

	local rebirthButton = Hud.CreateButton(actionPanel, {
		name = "Rebirth",
		text = "REBIRTH  $3.00K",
		size = UDim2.new(1, -20, 0, 52),
		position = UDim2.fromOffset(10, 12),
		color = Hud.ButtonColor.rebirth,
		textSize = 17,
	})

	local lockButton = Hud.CreateButton(actionPanel, {
		name = "Lock",
		text = "LOCK BASE  $750",
		size = UDim2.new(1, -20, 0, 46),
		position = UDim2.fromOffset(10, 74),
		color = Hud.ButtonColor.lock,
		textSize = 16,
	})

	local lockStatus = label(actionPanel, {
		text = "Base unlocked",
		size = 13,
		position = UDim2.fromOffset(14, 122),
		sizeProp = UDim2.new(1, -28, 0, 20),
		color = THEME.dim,
		font = Enum.Font.GothamSemibold,
	})
	lockStatus.Name = "LockStatus"

	-- Right side: the steal board listing every other base and its contents.
	local board = Instance.new("Frame")
	board.Name = "StealBoard"
	board.Size = UDim2.fromOffset(258, 306)
	board.Position = UDim2.new(1, -18, 0, 190)
	board.AnchorPoint = Vector2.new(1, 0)
	board.BackgroundColor3 = THEME.panel
	board.BackgroundTransparency = 0.1
	board.BorderSizePixel = 0
	board.Parent = root
	round(board, 14)
	stroke(board, Color3.fromRGB(70, 78, 108), 2)

	local boardTitle = label(board, {
		text = "STEAL BOARD",
		size = 15,
		position = UDim2.fromOffset(14, 10),
		sizeProp = UDim2.new(1, -28, 0, 22),
		color = THEME.accent,
		font = Enum.Font.GothamBlack,
	})
	boardTitle.Name = "Title"

	local boardList = Instance.new("ScrollingFrame")
	boardList.Name = "List"
	boardList.Size = UDim2.new(1, -20, 1, -52)
	boardList.Position = UDim2.fromOffset(10, 40)
	boardList.BackgroundTransparency = 1
	boardList.BorderSizePixel = 0
	boardList.ScrollBarThickness = 4
	boardList.CanvasSize = UDim2.new()
	boardList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	boardList.Parent = board
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = boardList

	-- Centre-bottom: the toast / message area.
	local toastArea = Instance.new("Frame")
	toastArea.Name = "Toasts"
	toastArea.Size = UDim2.fromOffset(520, 120)
	toastArea.Position = UDim2.new(0.5, 0, 1, -190)
	toastArea.AnchorPoint = Vector2.new(0.5, 1)
	toastArea.BackgroundTransparency = 1
	toastArea.Parent = root
	local toastLayout = Instance.new("UIListLayout")
	toastLayout.Padding = UDim.new(0, 6)
	toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
	toastLayout.Parent = toastArea

	-- Bottom-left: controls hint.
	local hint = Instance.new("Frame")
	hint.Name = "Controls"
	hint.Size = UDim2.fromOffset(300, 76)
	hint.Position = UDim2.new(0, 18, 1, -18)
	hint.AnchorPoint = Vector2.new(0, 1)
	hint.BackgroundColor3 = THEME.panel
	hint.BackgroundTransparency = 0.3
	hint.BorderSizePixel = 0
	hint.Parent = root
	round(hint, 12)
	label(hint, {
		text = "WASD move  ·  SPACE jump  ·  scroll to zoom",
		size = 13,
		position = UDim2.fromOffset(12, 8),
		sizeProp = UDim2.new(1, -24, 0, 18),
		color = THEME.dim,
		font = Enum.Font.GothamSemibold,
	})
	label(hint, {
		text = "E / click prompt to interact  ·  B shop  ·  R rebirth",
		size = 13,
		position = UDim2.fromOffset(12, 28),
		sizeProp = UDim2.new(1, -24, 0, 18),
		color = THEME.dim,
		font = Enum.Font.GothamSemibold,
	})
	label(hint, {
		text = "Steal rival brainrots, then lock your base",
		size = 13,
		position = UDim2.fromOffset(12, 48),
		sizeProp = UDim2.new(1, -24, 0, 18),
		color = Color3.fromRGB(255, 200, 120),
		font = Enum.Font.GothamSemibold,
	})

	-- The wave warning banner, hidden until the wave is coming.
	local waveBanner = Instance.new("Frame")
	waveBanner.Name = "WaveBanner"
	waveBanner.Size = UDim2.fromOffset(620, 76)
	waveBanner.Position = UDim2.new(0.5, 0, 0, 22)
	waveBanner.AnchorPoint = Vector2.new(0.5, 0)
	waveBanner.BackgroundColor3 = Color3.fromRGB(140, 26, 54)
	waveBanner.BackgroundTransparency = 0.05
	waveBanner.BorderSizePixel = 0
	waveBanner.Visible = false
	waveBanner.Parent = root
	round(waveBanner, 14)
	stroke(waveBanner, Color3.fromRGB(255, 140, 170), 2)
	label(waveBanner, {
		text = "HAZARD WAVE INCOMING",
		scaled = true,
		sizeProp = UDim2.new(1, -24, 0, 34),
		position = UDim2.fromOffset(12, 6),
		color = Color3.fromRGB(255, 236, 240),
		font = Enum.Font.GothamBlack,
	})
	local waveSub = label(waveBanner, {
		text = "DASH TO YOUR BASE",
		scaled = true,
		sizeProp = UDim2.new(1, -24, 0, 24),
		position = UDim2.fromOffset(12, 42),
		color = Color3.fromRGB(255, 190, 205),
		font = Enum.Font.GothamBold,
	})
	waveSub.Name = "Sub"

	local handle = {
		root = root,
		WaveBanner = waveBanner,
		RebirthButton = rebirthButton,
		LockButton = lockButton,
		displayedMoney = 0,
		targetMoney = 0,
		moneyLabel = moneyLabel,
		incomeLabel = incomeLabel,
		multBadge = multBadge,
		rebirthBadge = rebirthBadge,
		lockStatus = lockStatus,
		toastArea = toastArea,
		boardList = boardList,
		snapshot = nil,
	}

	function handle.SetMoney(value)
		handle.targetMoney = value
	end

	-- A small green flash behind the money label whenever income lands, so the
	-- number reads as actively ticking even when digits do not change.
	function handle.PulseMoney()
		if not moneyPanel.Parent then
			return
		end
		moneyPanel.BackgroundColor3 = Color3.fromRGB(26, 62, 44)
		TweenService:Create(moneyPanel, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = THEME.panel,
		}):Play()
	end

	function handle.SetIncome(value)
		incomeLabel.Text = Format.Rate(value) .. " income"
	end

	function handle.SetMultiplier(multiplier, rebirths, cost)
		multBadge.Text = "x" .. string.format("%.1f", multiplier) .. " MULT"
		rebirthBadge.Text = "REBIRTH " .. rebirths
		rebirthButton.Text = "REBIRTH  " .. Format.Money(cost)
	end

	function handle.SetLock(remaining, cost)
		if remaining > 0 then
			lockButton.Text = "LOCKED  " .. Format.Time(remaining)
			lockButton.BackgroundColor3 = Color3.fromRGB(52, 96, 72)
			lockStatus.Text = "Base shielded for " .. Format.Time(remaining)
			lockStatus.TextColor3 = Color3.fromRGB(150, 255, 190)
		else
			lockButton.Text = "LOCK BASE  " .. Format.Money(cost)
			lockButton.BackgroundColor3 = Hud.ButtonColor.lock
			lockStatus.Text = "Base unlocked - anyone can steal"
			lockStatus.TextColor3 = THEME.danger
		end
	end

	function handle.SetWave(active, warning)
		if active then
			waveBanner.Visible = true
			if warning and warning > 0 then
				waveBanner.Sub.Text = "DASH HOME IN " .. math.ceil(warning) .. "s"
			else
				waveBanner.Sub.Text = "THE WAVE IS HERE - GET TO YOUR BASE"
			end
		else
			waveBanner.Visible = false
		end
	end

	-- Toasts slide up and fade; at most four are on screen at once.
	local toastOrder = 0
	function handle.Toast(text, color, duration)
		toastOrder += 1
		local toast = Instance.new("TextLabel")
		toast.Name = "Toast"
		toast.Size = UDim2.new(1, 0, 0, 34)
		toast.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
		toast.BackgroundTransparency = 0.1
		toast.BorderSizePixel = 0
		toast.Font = Enum.Font.GothamBold
		toast.TextSize = 17
		toast.TextColor3 = color or THEME.text
		toast.Text = text
		toast.LayoutOrder = toastOrder
		toast.Parent = toastArea
		round(toast, 10)
		stroke(toast, (color or THEME.text):Lerp(Color3.fromRGB(20, 20, 30), 0.5), 1.5)
		local fade = TweenService:Create(toast, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
		task.delay(duration or 2.6, function()
			fade:Play()
			task.wait(0.5)
			toast:Destroy()
		end)
		-- Keep at most four toasts on screen, oldest first. Only toasts are
		-- collected; the UIListLayout is never touched.
		local toasts = {}
		for _, child in ipairs(toastArea:GetChildren()) do
			if child:IsA("TextLabel") then
				table.insert(toasts, child)
			end
		end
		while #toasts > 4 do
			local oldest = table.remove(toasts, 1)
			if oldest then
				oldest:Destroy()
			end
		end
	end

	-- The steal board: one row per other base, colour-coded by lock state. The
	-- rows are rebuilt only when something they show actually changes, so the
	-- panel does not flicker at the snapshot rate.
	local lastBoardSignature = nil
	function handle.RenderBoard(bases, myPlotIndex)
		local signature = {}
		for _, base in ipairs(bases) do
			table.insert(signature, table.concat({
				base.plotIndex,
				base.ownerName,
				#base.slots,
				math.floor(base.rate),
				base.locked and math.ceil(base.lockRemaining) or 0,
			}, "|"))
		end
		local sig = table.concat(signature, ",") .. "#" .. tostring(myPlotIndex)
		if sig == lastBoardSignature then
			return
		end
		lastBoardSignature = sig

		for _, child in ipairs(boardList:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local order = 0
		for _, base in ipairs(bases) do
			order += 1
			local row = Instance.new("Frame")
			row.Name = "Base" .. base.plotIndex
			row.Size = UDim2.new(1, -6, 0, 52)
			row.BackgroundColor3 = base.plotIndex == myPlotIndex and Color3.fromRGB(34, 48, 62) or Color3.fromRGB(28, 30, 44)
			row.BorderSizePixel = 0
			row.LayoutOrder = order
			row.Parent = boardList
			round(row, 9)

			local title = label(row, {
				text = (base.plotIndex == myPlotIndex and "YOUR BASE  " or ("PLOT " .. base.plotIndex .. "  ")) .. base.ownerName,
				size = 13,
				position = UDim2.fromOffset(10, 4),
				sizeProp = UDim2.new(1, -20, 0, 16),
				color = base.plotIndex == myPlotIndex and Color3.fromRGB(160, 255, 200) or THEME.text,
			})
			title.Name = "Name"

			local status = label(row, {
				text = base.locked and ("LOCKED " .. Format.Time(base.lockRemaining)) or (#base.slots .. "/" .. Config.SlotsPerPlot .. "  " .. Format.Rate(base.rate)),
				size = 12,
				position = UDim2.fromOffset(10, 21),
				sizeProp = UDim2.new(1, -20, 0, 14),
				color = base.locked and Color3.fromRGB(255, 150, 170) or THEME.dim,
				font = Enum.Font.GothamSemibold,
			})
			status.Name = "Status"

			local tip = label(row, {
				text = #base.slots == 0 and "empty" or (base.locked and "shielded" or "walk over to steal"),
				size = 11,
				position = UDim2.fromOffset(10, 35),
				sizeProp = UDim2.new(1, -20, 0, 13),
				color = base.locked and Color3.fromRGB(255, 140, 160) or Color3.fromRGB(255, 208, 130),
				font = Enum.Font.GothamSemibold,
			})
			tip.Name = "Hint"
		end
	end

	-- Money counts up toward the server value instead of snapping, so the HUD
	-- visibly ticks. A purchase is a sudden drop, so a drop is applied at once
	-- and only gains are eased.
	task.spawn(function()
		local lastTarget = 0
		while root.Parent do
			local dt = task.wait(0.04)
			local target = handle.targetMoney
			if target < lastTarget - 0.5 then
				handle.displayedMoney = target
			else
				local diff = target - handle.displayedMoney
				if math.abs(diff) < 0.6 then
					handle.displayedMoney = target
				else
					handle.displayedMoney += diff * math.clamp(dt * 9, 0, 1)
				end
			end
			lastTarget = target
			moneyLabel.Text = Format.Money(handle.displayedMoney)
		end
	end)

	return handle
end

return Hud
