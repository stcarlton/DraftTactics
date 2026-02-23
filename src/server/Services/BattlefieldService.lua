--[[
BattlefieldService.lua

Role:
- Builds and initializes battlefield structures.
- Spawns objectives and static elements.

Owns:
- Map construction.
- Objective instantiation.
- Static geometry setup.

Does NOT:
- Run battle simulation.
- Execute unit logic.
- Apply damage.
- Evaluate victory.

Rules:
- Server-only.
- No per-frame logic.
- Deterministic setup.

Used By:
- Main.server.lua
- BattleService
]]

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BattlefieldLayout = require(script.Parent.Parent.Runtime.BattlefieldLayout)
local ObjectiveRuntime  = require(script.Parent.Parent.Runtime.ObjectiveRuntime)

local ObjectiveConfigs  = require(ReplicatedStorage.Shared.Configs.ObjectiveConfigs)
local GridUtil          = require(ReplicatedStorage.Shared.Util.GridUtil)
local TowerConfigs 		= require(ReplicatedStorage.Shared.Configs.TowerConfigs)

local DEFAULT_TOWER_CONFIG = TowerConfigs.Default

local BattlefieldService = {}

BattlefieldService.Objectives = {}
BattlefieldService.Layouts    = {}
BattlefieldService.Towers     = {}

BattlefieldService.Built = false

local function buildObjective(teamId)
	local config = ObjectiveConfigs.MainObjective
	local area = config.GridArea[teamId]
	assert(area, "Missing GridArea for team " .. teamId)

	local template = ServerStorage:FindFirstChild(config.ModelName)
	assert(template, "Missing objective model: " .. config.ModelName)

	local model = template:Clone()
	model.Parent = Workspace.Battle

	local pos = GridUtil.AreaCenter(
		area.RowStart,
		area.RowEnd,
		area.ColStart,
		area.ColEnd,
		config.Height,
		area.rowT,
		area.colT
	)


	local facing = config.Facing[teamId]
	assert(facing, "Missing facing for team " .. teamId)

	model:SetPrimaryPartCFrame(
		CFrame.new(pos, pos + facing)
	)

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = true
		end
	end

	local objective = ObjectiveRuntime.new(
		config.Id .. "_" .. teamId,
		model,
		config,
		teamId
	)

	return objective
end

local function spawnTowerModel(towerSpec)
	local template = ServerStorage:FindFirstChild("TowerModel")
	assert(template, "Missing TowerModel in ServerStorage")

	local model = template:Clone()

	if not model.PrimaryPart then
		local root = Instance.new("Part")
		root.Name = "Root"
		root.Size = Vector3.new(1,1,1)
		root.Transparency = 1
		root.Anchored = true
		root.CanCollide = false
		root.Parent = model
		model.PrimaryPart = root

		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") and part ~= root then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = root
				weld.Part1 = part
				weld.Parent = root
				part.Anchored = false
			end
		end
	end

	model:SetPrimaryPartCFrame(
		CFrame.lookAt(
			towerSpec.BasePosition,
			towerSpec.BasePosition + towerSpec.Facing
		)
	)

	model.Parent = Workspace.Battle
	return model
end

function BattlefieldService:Build()
	assert(not self.Built, "BattlefieldService.Build called twice")

	self.Objectives["A"] = buildObjective("A")
	self.Objectives["B"] = buildObjective("B")
	self.Layouts["A"] = BattlefieldLayout.Build("A")
	self.Layouts["B"] = BattlefieldLayout.Build("B")
	self.Towers["A"] = self.Layouts["A"].Towers
	self.Towers["B"] = self.Layouts["B"].Towers

	for teamId, layout in pairs(self.Layouts) do
		for _, tower in ipairs(layout.Towers) do
			local model = spawnTowerModel(tower)
			tower.Model = model

			local cfg = DEFAULT_TOWER_CONFIG
			local root = model.PrimaryPart
			local towerCF = root.CFrame
			local basePos = root.Position

			local ladderOffsetWS = towerCF:VectorToWorldSpace(cfg.LadderOffset)
			local topOffsetWS    = towerCF:VectorToWorldSpace(cfg.TopOffset)

			local slotOffsetsWS = {}
			for slot, localOffset in pairs(cfg.SlotOffsets) do
				slotOffsetsWS[slot] = towerCF:VectorToWorldSpace(localOffset)
			end

			tower.Runtime = {
				BasePosition = basePos + ladderOffsetWS,
				TopPosition  = basePos + topOffsetWS,
				SlotOffsets  = slotOffsetsWS,
				OccupiedSlots = {},
			}

		end
	end

	self.Built = true
end

return BattlefieldService
