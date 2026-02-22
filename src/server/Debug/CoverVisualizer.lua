-- CoverVisualizer.lua
--
-- Debug-only utility for visualizing CoverNodes in the world.
-- Spawns simple wall parts so designers can see:
--   • where cover exists
--   • which direction it faces
--   • how dense the cover field is
--
-- This module has NO gameplay effect.
-- It exists only to validate BattlefieldCover topology.

local Workspace = game:GetService("Workspace")
local BattlefieldCover = require(game.ServerScriptService.Server.Runtime.BattlefieldCover)

local CoverVisualizer = {}

local WALL_SIZE = Vector3.new(4, 4, 1)
local WALL_HEIGHT_OFFSET = -6
local WALL_COLOR = Color3.fromRGB(120, 120, 120)
local WALL_MATERIAL = Enum.Material.Concrete

local function getFolder()
	local folder = Workspace.Battle:FindFirstChild("CoverVisuals")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CoverVisuals"
		folder.Parent = Workspace.Battle
	end
	return folder
end

function CoverVisualizer:Draw()
	local folder = getFolder()
	folder:ClearAllChildren()

	for _, node in ipairs(BattlefieldCover.Nodes) do
		local wall = Instance.new("Part")
		wall.Name = "CoverWall_" .. node.Id
		wall.Anchored = true
		wall.CanCollide = false
		wall.Size = WALL_SIZE
		wall.Material = WALL_MATERIAL
		wall.Color = WALL_COLOR

		local wallPos =
			node.Position
			+ node.Forward * BattlefieldCover.WALL_FORWARD_OFFSET
			+ Vector3.new(0, WALL_HEIGHT_OFFSET, 0)

		wall.CFrame = CFrame.new(
			wallPos,
			wallPos - node.Forward
		)

		wall.Parent = folder
	end
end

return CoverVisualizer
