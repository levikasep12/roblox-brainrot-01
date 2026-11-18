-- HudController: the heads-up display. Top-left is money (tweened so ticks are
-- visible), income and multiplier, with a small persistent "x2" badge beside
-- them while the wave bonus runs. Top-right is the roster sidebar. Bottom-left
-- holds the Rebirth and Lock Base buttons.
--
-- The hazard banner is the one screen the player complained about, so its rules
-- are explicit here:
--   * small: 380x36, text 13, one short line.
--   * "warning" and "sweeping" are gameplay-critical and stay up while active.
--   * "passed" is transient: shown ~2.5s, then the banner hides entirely; the
--     x2 state lives on as the badge next to the money, not as banner text.
--   * no toast is produced for a passed wave (ToastController is never told
--     about it), so the player never gets two notices for one event.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Theme)

local HudController = {}

local BANNER_PASSED_SECONDS = 2.5

local player = Players.LocalPlayer
local state
local gui
local elements = {}

local displayedMoney = 0

local function applyBanner(hazard)
	local banner = elements.banner
	local bannerLabel = elements.bannerLabel
	if not banner then
		return
	end
	local now = os.clock()
	local phase = hazard and hazard.phase or "idle"
	local previous = elements.lastPhase or "idle"
	elements.lastPhase = phase

	if phase == "warning" then
		-- Gameplay-critical: stays up for the whole countdown.
		banner.Visible = true
		banner.BackgroundColor3 = Color3.fromRGB(92, 66, 12)
		elements.bannerStroke.Color = Theme.Colors.warning
		bannerLabel.TextColor3 = Theme.Colors.warning
		bannerLabel.Text = ("HAZARD WAVE IN %ds - GET HOME"):format(math.max(1, math.ceil(hazard.left or 0)))
		elements.bannerHideAt = nil
	elseif phase == "sweeping" then
		-- Gameplay-critical: stays up while the wall crosses the map.
		banner.Visible = true
		banner.BackgroundColor3 = Color3.fromRGB(96, 22, 34)
		elements.bannerStroke.Color = Theme.Colors.danger
		bannerLabel.TextColor3 = Color3.fromRGB(255, 214, 220)
		bannerLabel.Text = "WAVE SWEEPING - DASH HOME NOW"
		elements.bannerHideAt = nil
	elseif phase == "passed" then
		-- Transient: only on the transition into "passed", for ~2.5s. Repeated
		-- state pushes during the same x2 window must not re-show it, and the
		-- x2 state lives on in the badge instead of the banner.
		if previous ~= "passed" and elements.passedShownFor ~= (hazard.x2Left or 0) then
			elements.passedShownFor = hazard.x2Left
			banner.Visible = true
			banner.BackgroundColor3 = Color3.fromRGB(20, 62, 38)
			elements.bannerStroke.Color = Theme.Colors.ok
			bannerLabel.TextColor3 = Color3.fromRGB(198, 255, 214)
			bannerLabel.Text = "WAVE PASSED - INCOME x2"
			elements.bannerHideAt = now + BANNER_PASSED_SECONDS
		end
	else
		banner.Visible = false
		elements.bannerHideAt = nil
		elements.passedShownFor = nil
	end
end

local function applyState(snapshot)
	if not snapshot then
		return
	end
	elements.moneyLabel.Text = Theme.formatMoney(displayedMoney)
	elements.incomeLabel.Text = ("+%s /sec"):format(Theme.formatMoney(snapshot.income))
	elements.multLabel.Text = ("x%.2f rebirth"):format(snapshot.multiplier)
	elements.rebirthButton.Text = ("REBIRTH  %s"):format(Theme.formatMoney(snapshot.rebirthCost))
	elements.rebirthButton.BackgroundColor3 = snapshot.money >= snapshot.rebirthCost
		and Color3.fromRGB(64, 34, 78)
		or Theme.Colors.panelSoft
	if snapshot.lockLeft > 0 then
		elements.lockButton.Text = ("LOCKED  %ds"):format(math.ceil(snapshot.lockLeft))
		elements.lockButton.BackgroundColor3 = Color3.fromRGB(26, 66, 74)
	else
		elements.lockButton.Text = ("LOCK BASE  %s"):format(Theme.formatMoney(snapshot.lockCost))
		elements.lockButton.BackgroundColor3 = Theme.Colors.panelSoft
	end
	elements.x2Badge.Visible = snapshot.x2 == true
	local used = 0
	for _ in pairs(snapshot.slots or {}) do
		used += 1
	end
	elements.slotsLabel.Text = ("BASE %d  ·  %d/%d slots"):format(snapshot.plotIndex, used, 6)
end

local function renderRoster(roster)
	local list = elements.rosterList
	if not list then
		return
	end
	list:ClearAllChildren()
	local sorted = table.clone(roster or {})
	table.sort(sorted, function(a, b)
		return (a.money or 0) > (b.money or 0)
	end)
	for index, row in ipairs(sorted) do
		local y = (index - 1) * 22
		local name = Theme.label(list, "Name" .. index, ("%d. %s"):format(index, row.name), UDim2.new(0.62, 0, 0, 20), UDim2.fromOffset(0, y), 12)
		name.TextTruncate = Enum.TextTruncate.AtEnd
		if row.name == player.DisplayName then
			name.TextColor3 = Theme.Colors.income
		end
		local value = Theme.label(list, "Value" .. index, Theme.formatMoney(row.money or 0), UDim2.new(0.38, 0, 0, 20), UDim2.new(0.62, 0, 0, y), 12, Theme.Colors.money)
		value.TextXAlignment = Enum.TextXAlignment.Right
	end
end

local function buildMoneyPanel(parent)
	local panel = Theme.panel(parent, "MoneyPanel", UDim2.fromOffset(272, 128), UDim2.fromOffset(16, 16))
	elements.moneyPanel = panel

	Theme.label(panel, "Caption", "CASH", UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 0), 11, Theme.Colors.dim)

	local money = Theme.label(panel, "Money", "$0", UDim2.new(0.62, 0, 0, 34), UDim2.fromOffset(0, 16), 28, Theme.Colors.money)
	money.Font = Theme.FontBlack
	elements.moneyLabel = money

	local x2 = Theme.label(panel, "X2Badge", "x2", UDim2.fromOffset(38, 22), UDim2.fromOffset(180, 22), 15, Color3.fromRGB(24, 20, 6))
	x2.BackgroundColor3 = Theme.Colors.x2
	x2.BackgroundTransparency = 0
	x2.Font = Theme.FontBlack
	x2.TextXAlignment = Enum.TextXAlignment.Center
	x2.Visible = false
	local x2Corner = Instance.new("UICorner")
	x2Corner.CornerRadius = UDim.new(0, 6)
	x2Corner.Parent = x2
	elements.x2Badge = x2

	local income = Theme.label(panel, "Income", "+$0 /sec", UDim2.new(1, 0, 0, 18), UDim2.fromOffset(0, 54), 13, Theme.Colors.income)
	elements.incomeLabel = income

	local mult = Theme.label(panel, "Multiplier", "x1.00 rebirth", UDim2.new(1, 0, 0, 16), UDim2.fromOffset(0, 74), 11, Theme.Colors.dim)
	elements.multLabel = mult

	local slots = Theme.label(panel, "Slots", "BASE 1  ·  0/6 slots", UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 92), 11, Theme.Colors.dim)
	elements.slotsLabel = slots

	return panel
end

local function buildRosterPanel(parent)
	local panel = Theme.panel(parent, "RosterPanel", UDim2.fromOffset(232, 210), UDim2.new(1, -16, 0, 16), Vector2.new(1, 0))
	Theme.label(panel, "Caption", "RICHEST CROOKS", UDim2.new(1, 0, 0, 16), UDim2.fromOffset(0, 0), 11, Theme.Colors.dim)
	local list = Instance.new("Frame")
	list.Name = "RosterList"
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, 0, 1, -22)
	list.Position = UDim2.fromOffset(0, 20)
	list.Parent = panel
	elements.rosterList = list
	return panel
end

local function buildActions(parent)
	local holder = Instance.new("Frame")
	holder.Name = "Actions"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(272, 76)
	holder.Position = UDim2.new(0, 16, 1, -92)
	holder.Parent = parent

	local rebirth = Theme.button(holder, "RebirthButton", "REBIRTH  $1,500", UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 0), Color3.fromRGB(56, 34, 72))
	rebirth.TextXAlignment = Enum.TextXAlignment.Center
	elements.rebirthButton = rebirth

	local lock = Theme.button(holder, "LockButton", "LOCK BASE  $250", UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 40), Theme.Colors.panelSoft)
	lock.TextXAlignment = Enum.TextXAlignment.Center
	elements.lockButton = lock

	return holder
end

local function buildBanner(parent)
	-- 380x36, text 13: deliberately small, per the banner rules.
	local banner = Instance.new("Frame")
	banner.Name = "HazardBanner"
	banner.Size = UDim2.fromOffset(380, 36)
	banner.Position = UDim2.new(0.5, 0, 0, 14)
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.BackgroundColor3 = Color3.fromRGB(92, 66, 12)
	banner.BackgroundTransparency = 0.05
	banner.BorderSizePixel = 0
	banner.Visible = false
	banner.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = banner

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.warning
	stroke.Thickness = 1
	stroke.Parent = banner
	elements.bannerStroke = stroke

	local label = Instance.new("TextLabel")
	label.Name = "Message"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Theme.FontBold
	label.TextSize = 13
	label.TextColor3 = Theme.Colors.warning
	label.Text = ""
	label.Parent = banner
	elements.bannerLabel = label

	elements.banner = banner
	return banner
end

function HudController.build()
	state = require(script.Parent.ClientState)
	gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	buildMoneyPanel(gui)
	buildRosterPanel(gui)
	local actions = buildActions(gui)
	buildBanner(gui)

	elements.rebirthButton.Activated:Connect(function()
		local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
		remotes.Rebirth:FireServer()
	end)

	elements.lockButton.Activated:Connect(function()
		local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
		remotes.BuyLock:FireServer()
	end)

	state.onChange(function(kind)
		local current = state.get()
		if kind == "state" then
			applyState(current.snapshot)
			renderRoster(current.roster)
		elseif kind == "hazard" then
			applyBanner(current.hazard)
		end
	end)

	local snapshot = state.get().snapshot
	if snapshot then
		applyState(snapshot)
		renderRoster(state.get().roster)
	end
	applyBanner(state.get().hazard)

	-- Money tween: frame-rate independent, and fast enough to look live.
	RunService.RenderStepped:Connect(function(dt)
		local current = state.get().snapshot
		if not current then
			return
		end
		local target = current.money or 0
		local delta = target - displayedMoney
		if math.abs(delta) < 1 then
			displayedMoney = target
		else
			displayedMoney = displayedMoney + delta * math.min(1, dt * 10)
		end
		elements.moneyLabel.Text = Theme.formatMoney(displayedMoney)

		-- The transient "passed" banner hides itself; it never becomes a toast.
		if elements.banner and elements.bannerHideAt and os.clock() >= elements.bannerHideAt then
			elements.banner.Visible = false
			elements.bannerHideAt = nil
		end
	end)

	actions.Visible = true

	return gui
end

return HudController
