-- TacticalCamera.client.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

player.CharacterAdded:Connect(function(char) char:Destroy() end)
if player.Character then player.Character:Destroy() end

camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 70

local GamePhaseValue = ReplicatedStorage:WaitForChild("State"):WaitForChild("GamePhaseValue")
local DeploymentArea = workspace:WaitForChild("Map"):WaitForChild("ArenaFloor")

local BATTLE_RADIUS = 60
local BATTLE_HEIGHT = 260
local BATTLE_CENTER_RIGHT_OFFSET = 0
local BATTLE_CENTER_FWD_OFFSET   = -30

local function ComputeBattleCFrame()
	local area = DeploymentArea
	local center = area.Position

	local forward = area.CFrame.LookVector
	local right   = area.CFrame.RightVector

	local focus =
		center
		+ right   * BATTLE_CENTER_RIGHT_OFFSET
		+ forward * BATTLE_CENTER_FWD_OFFSET

	local camPos =
		focus
	- forward * BATTLE_RADIUS
		+ Vector3.new(0, BATTLE_HEIGHT, 0)

	return CFrame.lookAt(camPos, focus, Vector3.new(0, 1, 0))
end

local ZOOM_IN_FACTOR = 1.25
local LEFT_SHIFT_FACTOR = 0

local function ComputeTopDownCFrame()
	local area = DeploymentArea
	local center = area.Position
	local size = area.Size

	local halfX = size.X * 0.5
	local halfZ = size.Z * 0.5

	local viewport = camera.ViewportSize
	local aspect = viewport.X / math.max(viewport.Y, 1)

	local vFov = math.rad(camera.FieldOfView)
	local hFov = 2 * math.atan(math.tan(vFov/2) * aspect)

	local heightForX = halfX / math.tan(hFov/2)
	local heightForZ = halfZ / math.tan(vFov/2)
	local height = math.max(heightForX, heightForZ)

	height *= ZOOM_IN_FACTOR

	local right = area.CFrame.RightVector
	local leftShift = -right * (size.X * LEFT_SHIFT_FACTOR)

	local camPos =
		center
		+ Vector3.new(0, height, 0)
		+ leftShift

	return CFrame.lookAt(
		camPos,
		center + leftShift,
		Vector3.new(0,0,-1)
	)
end


local function GetDesiredCameraCFrame()
	if GamePhaseValue.Value == "PreBattle" then
		return ComputeTopDownCFrame()
	else
		return ComputeBattleCFrame()
	end
end

RunService:BindToRenderStep("TacticalCamera", Enum.RenderPriority.Camera.Value + 1, function()
	camera.CFrame = GetDesiredCameraCFrame()
end)
