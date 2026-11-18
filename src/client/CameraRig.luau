-- A third-person orbit camera. Roblox's default camera ignores arrow keys when
-- the chat or a text box holds focus, so this rig owns the camera outright:
-- right-drag or Left/Right arrows orbit, Up/Down tilt, the wheel zooms.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CameraRig = {}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local yaw = math.pi
local pitch = math.rad(-16)
local distance = 28
local minDistance = 12
local maxDistance = 78
local dragging = false
local lastMouse = Vector2.zero
local enabled = false

local function focusPoint(): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	return root.Position + Vector3.new(0, 2.4, 0)
end

local function applyCamera()
	local focus = focusPoint()
	if not focus then
		return
	end
	local current = Workspace.CurrentCamera
	if not current then
		return
	end
	camera = current
	local offset = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.new(0, 0, distance)
	camera.CFrame = CFrame.lookAt(focus + offset.Position, focus)
end

function CameraRig.start()
	if enabled then
		return
	end
	enabled = true
	camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 68

	local function bindCharacter()
		local focus = focusPoint()
		if focus then
			yaw = math.pi
			pitch = math.rad(-16)
			applyCamera()
		end
	end

	if player.Character then
		bindCharacter()
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		bindCharacter()
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			dragging = true
			lastMouse = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if dragging and not processed then
				local current = Vector2.new(input.Position.X, input.Position.Y)
				local delta = current - lastMouse
				lastMouse = current
				yaw -= delta.X * 0.006
				pitch = math.clamp(pitch - delta.Y * 0.005, math.rad(-70), math.rad(28))
			end
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			distance = math.clamp(distance - input.Position.Z * 4, minDistance, maxDistance)
		end
	end)

	RunService:BindToRenderStep("BrainrotCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local turn = 0
		local tilt = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.Left) then
			turn += 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Right) then
			turn -= 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Up) then
			tilt += 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Down) then
			tilt -= 1
		end
		if turn ~= 0 then
			yaw += turn * dt * 1.8
		end
		if tilt ~= 0 then
			pitch = math.clamp(pitch + tilt * dt * 1.2, math.rad(-70), math.rad(28))
		end
		applyCamera()
	end)
end

return CameraRig
