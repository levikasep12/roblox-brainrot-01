-- Player lifecycle: joining, plot assignment, the dash-home ability, and the
-- wave-safe check. Owns the character map used by Steal for range checks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlotLayout = require(ReplicatedStorage.Shared.PlotLayout)
local Store = require(script.Parent.Store)
local Bases = require(script.Parent.Bases)

local PlayerService = {}

local characters: { [number]: Model } = {}

function PlayerService.characterFor(userId: number): Model?
	local character = characters[userId]
	if character and character.Parent then
		return character
	end
	return nil
end

function PlayerService.rootFor(userId: number): BasePart?
	local character = PlayerService.characterFor(userId)
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function PlayerService.positionFor(userId: number): Vector3?
	local root = PlayerService.rootFor(userId)
	return root and root.Position or nil
end

function PlayerService.registerCharacter(player: Player, character: Model)
	characters[player.UserId] = character
	character:SetAttribute("BrainrotRush", true)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 22
		humanoid.JumpPower = 52
		humanoid.UseJumpPower = true
	end
	character.AncestryChanged:Connect(function()
		if characters[player.UserId] == character then
			characters[player.UserId] = nil
		end
	end)
end

function PlayerService.dashHome(profile, player: Player): (boolean, string)
	local now = os.clock()
	if now < profile.dashCooldownUntil then
		return false, "Dash recharging"
	end
	local character = PlayerService.characterFor(profile.userId)
	if not character then
		return false, "No character"
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, "No character"
	end
	local destination = if profile.plotIndex > 0
		then PlotLayout.spawnPosition(profile.plotIndex)
		else Vector3.new(0, 4, -20)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local oldSpeed = humanoid and humanoid.WalkSpeed or 22
	if humanoid then
		humanoid.WalkSpeed = GameConfig.Dash.walkSpeed
	end
	character:PivotTo(CFrame.new(destination) * CFrame.Angles(0, math.rad(180), 0))
	profile.dashUntil = now + GameConfig.Dash.duration
	profile.dashCooldownUntil = now + GameConfig.Dash.cooldown
	task.delay(GameConfig.Dash.duration, function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = oldSpeed
		end
	end)
	return true, "Dashed home!"
end

function PlayerService.isSafeAtBase(profile, position: Vector3): boolean
	if profile.plotIndex == 0 then
		return false
	end
	return PlotLayout.isInside(profile.plotIndex, position, GameConfig.Hazard.safeRadius)
end

function PlayerService.attachPlayer(player: Player)
	local existing = Store.getPlayer(player.UserId)
	if existing then
		return existing
	end
	local profile = Store.newProfile(player.UserId, player.DisplayName)
	profile.plotIndex = Store.claimFreePlot()
	Store.state.players[player.UserId] = profile
	Bases.syncPlayer(profile)
	return profile
end

function PlayerService.detachPlayer(player: Player)
	local profile = Store.state.players[player.UserId]
	if profile and profile.plotIndex > 0 then
		Bases.clearPlot(profile.plotIndex)
	end
	characters[player.UserId] = nil
	Store.state.players[player.UserId] = nil
end

return PlayerService
