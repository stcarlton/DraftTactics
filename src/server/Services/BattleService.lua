--[[
BattleService.lua

Role:
- Orchestrates a single battle instance.
- Controls battle lifecycle + state transitions.
- Spawns units from deployment snapshot.
- Evaluates victory conditions.

Owns:
- Active unit list.
- BattleState.
- Simulation start/stop.
- Win/loss resolution.

Does NOT:
- Execute per-unit logic (UnitRuntime).
- Decide tactics (Brains).
- Compute damage (StatResolver).
- Move characters (MovementController).
- Build battlefield geometry (BattlefieldService).

Invariants:
- Server-authoritative.
- Single active battle (MVP).
- Deterministic update order.
- Explicit enum-driven state transitions.

Collaborators:
- SpawnPlanBuilder
- UnitRegistry
- UnitRuntime
- BattlefieldService
- GamePhase
]]

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BattleState        = require(ReplicatedStorage.Shared.Types.BattleState)
local HealthBarStyle     = require(ReplicatedStorage.Shared.Presentation.HealthBarStyle)
local GridUtil 			 = require(ReplicatedStorage.Shared.Util.GridUtil)
local StatResolver 		 = require(ReplicatedStorage.Shared.Combat.StatResolver)
local UnitRegistry 		 = require(ReplicatedStorage.Shared.Registry.UnitRegistry)

local BattlefieldService = require(script.Parent.BattlefieldService)
local UnitRuntime        = require(script.Parent.Parent.Runtime.UnitRuntime)
local SpawnPlanBuilder   = require(script.Parent.SpawnPlanBuilder)

local BattleService = {}

if _G.__BattleService then
	return _G.__BattleService
end

BattleService.State = BattleState.Idle

BattleService.TeamA = nil
BattleService.TeamB = nil

BattleService.Units      = {}
BattleService.Objectives = {}
BattleService.Layouts    = {}
BattleService.Towers     = {}

BattleService.SharedState = {
	PreEngagement = true
}

BattleService.ExpectedUnitCount = 0
BattleService.SpawnedUnitCount  = 0

local TEAM_ENTRY = {
	A = {
		Position = Vector3.new(0, -7, GridUtil.MAP_SIZE / 2),
		Rotation = CFrame.Angles(0, math.rad(0), 0),
	},
	B = {
		Position = Vector3.new(0, -7, -GridUtil.MAP_SIZE / 2),
		Rotation = CFrame.Angles(0, math.rad(-180), 0),
	},
}

local function spawnModel(modelName, cframe)
	local template = ServerStorage:FindFirstChild(modelName)
	assert(template, "Missing model in ServerStorage: " .. modelName)

	local model = template:Clone()

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	model:SetPrimaryPartCFrame(cframe)
	model.Parent = Workspace.Battle

	return model
end

function BattleService:SpawnUnit(entry)
	local teamId = entry.TeamId
	local registry = UnitRegistry[entry.Class]

	local entryDef = TEAM_ENTRY[teamId]
	assert(entryDef, "Missing TEAM_ENTRY for team: " .. tostring(teamId))

	local baseCF =
		CFrame.new(entryDef.Position) *
		entryDef.Rotation

	local right = baseCF.RightVector
	local spawnPos = entryDef.Position + right * (entry.LateralOffset or 0)

	local spawnCF =
		CFrame.new(spawnPos) *
		entryDef.Rotation

	local model = spawnModel(registry.ModelName, spawnCF)

	local unit = UnitRuntime.new(
		entry.TeamId .. "_" .. entry.TileId .. "_" .. tostring(entry.SpawnIndex),
		model,
		registry.Config,
		registry.Brain
	)

	-----------------------------------------------------------------
	-- REQUIRED UNIT PROPERTIES
	-----------------------------------------------------------------

	unit.Root.Anchored = true
	unit.Team = teamId
	unit.Strategy = entry.Strategy
	unit.AllUnits = self.Units
	unit.ResolvedStats = StatResolver.GetInitialStats(unit)
	unit.Stealth = unit.ResolvedStats.Stealth
	unit.AmbushTime = unit.ResolvedStats.AmbushTime
	unit.SharedState = BattleService.SharedState
	
	local enemyTeamId = "B"
	if teamId == "B" then
		enemyTeamId = "A"
	end
	
	unit.FriendlyObjective = self.Objectives[teamId]
	unit.EnemyObjective = self.Objectives[enemyTeamId]
	
	if entry.Row == 6 then
		self:TryAssignTowerSlot(unit)
	end

	-----------------------------------------------------------------
	-- UI
	-----------------------------------------------------------------

	local gui = ReplicatedStorage.UI.HealthBar:Clone()
	gui.Parent = model:FindFirstChild("Head")
	unit.HealthGui = gui
	unit.HealthBar = gui.Bar

	unit.HealthBar.BackgroundColor3 =
		HealthBarStyle.TeamColors[unit.Team]
		or HealthBarStyle.TeamColors.Neutral

	table.insert(self.Units, unit)

	self.SpawnedUnitCount += 1

	if self.SpawnedUnitCount >= self.ExpectedUnitCount then
		self.State = BattleState.Running
		print("[BattleService] Battle running")
	end
end

function BattleService:TryAssignTowerSlot(unit)
	local layout = self.Layouts[unit.Team]
	if not layout then
		return
	end
	
	local bestDist = math.huge
	local bestTower = nil
	local bestSlot = nil
	
	for _, tower in ipairs(layout.Towers) do
		local rt = tower.Runtime
		local maxSlots = #rt.SlotOffsets

		for slot = 1, maxSlots do
			if not rt.OccupiedSlots[slot] then
				local dist = (unit.Root.Position - rt.BasePosition).Magnitude
				if dist < bestDist then
					bestDist = dist
					bestTower = tower
					bestSlot = slot
				end
			end
		end
	end
	
	if bestTower then
		bestTower.Runtime.OccupiedSlots[bestSlot] = unit

		unit.TowerAssignment = {
			Tower = bestTower,
			Slot  = bestSlot,
		}
	end
end

function BattleService:StartBattle()
	assert(self.TeamA, "BattleService.TeamA not set")
	assert(self.TeamB, "BattleService.TeamB not set")
	assert(BattlefieldService.Built, "BattlefieldService not built")

	self.State = BattleState.Spawning

	table.clear(self.Units)

	self.Objectives = BattlefieldService.Objectives
	self.Layouts    = BattlefieldService.Layouts
	self.Towers     = BattlefieldService.Towers

	local spawnPlan = SpawnPlanBuilder.Build({
		[self.TeamA.Id] = self.TeamA,
		[self.TeamB.Id] = self.TeamB,
	})

	self.ExpectedUnitCount = #spawnPlan
	self.SpawnedUnitCount  = 0

	for _, entry in ipairs(spawnPlan) do
		task.delay(entry.SpawnDelay, function()
			self:SpawnUnit(entry)
		end)
	end

	print("[BattleService] Spawning units...")
end

function BattleService:IsBattleOver()
	if self.State ~= BattleState.Running then
		return false
	end

	local objectiveA = self.Objectives["A"]
	local objectiveB = self.Objectives["B"]

	if not objectiveA.IsAlive or not objectiveB.IsAlive then
		self.State = BattleState.Ended
		return true
	end

	return false
end

_G.__BattleService = BattleService
return BattleService
