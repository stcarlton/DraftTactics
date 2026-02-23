--[[
BrainActions.lua

Role:
- Shared helper functions for Brains.

Does NOT:
- Execute actions.
- Modify runtime state.
- Store persistent state.

Rules:
- Pure logic only.
- No side effects.

Used By:
- InfantryBrain
- SniperBrain
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Intent = require(ReplicatedStorage.Shared.Types.Intent)
local Decision = require(ReplicatedStorage.Shared.Types.Decision)
local TowerPhase = require(ReplicatedStorage.Shared.Types.TowerPhase)

local BattlefieldCover = require(script.Parent.BattlefieldCover)

local CROSS_Z_THRESHOLD = 0

local BrainActions = {}

BrainActions.ARRIVAL_RADIUS = 0.5

function BrainActions.Melee(unit)
	unit.Decision = Decision.Melee
	unit.CurrentTarget = next(unit.AvailableMeleeTargets)
	unit.Intent = Intent.Melee
end

function BrainActions.Charge(unit, pos)
	unit.Decision = Decision.Charge
	unit.Intent = Intent.Move
	BattlefieldCover:UnReserve(unit)
	if not unit.CurrentChargeTarget or not unit.CurrentChargeTarget.IsAlive then
		unit.CurrentChargeTarget = BrainActions.AcquireChargeTarget(unit, pos)
	end
	unit.MoveDestination = unit.CurrentChargeTarget.Root.Position
end

function BrainActions.Hold(unit)
	unit.Decision = Decision.Hold
	unit.Intent = Intent.Hold
end

function BrainActions.SeekObjective(unit)
	unit.Decision = Decision.SeekObjective
	BattlefieldCover:AttackObjective(unit)
	if unit.AssignedCoverNode then
		BrainActions.Reposition(unit, unit.AssignedCoverNode)
	end
end

function BrainActions.SeekAcross(unit)
	unit.Decision = Decision.SeekAcross
	unit.Intent = Intent.Move
	BattlefieldCover:UnReserve(unit)

	local direction
	if unit.Team == "A" then
		direction = Vector3.new(0, 0, -1)
	else
		direction = Vector3.new(0, 0, 1)
	end
	unit.MoveDestination = unit.Root.Position + direction * 50
end


function BrainActions.SeekEnemy(unit, pos)
	unit.Decision = Decision.SeekEnemy

	local target = nil
	local bestDist = math.huge

	for enemy in pairs(unit.KnownEnemies) do
		local d = (enemy.Root.Position - pos).Magnitude
		if d < bestDist then
			bestDist = d
			target = enemy.Root.Position
		end
	end

	BattlefieldCover:UnReserve(unit)
	unit.Intent = Intent.Move
	unit.MoveDestination = target
end

function BrainActions.Destroy(unit)
	unit.Decision = Decision.Destroy
	unit.CurrentTarget = unit.EnemyObjective
	if not unit:HasBullet() then
		unit.Intent = Intent.Reload
	elseif unit.CurrentTarget then
		unit.Intent = Intent.Fire
	end
end

function BrainActions.Reposition(unit, node)
	unit.Decision = Decision.Reposition
	unit.Intent = Intent.Move
	unit.MoveDestination = node.Position
end

function BrainActions.Engage(unit, pos)
	unit.Decision = Decision.Engage

	local cantFire = true
	for _, target in pairs(unit.AvailableTargets) do
		if target == unit.CurrentTarget then
			cantFire = false
		end
	end

	if cantFire then
		unit.CurrentTarget = BrainActions.AcquireTarget(unit, pos)
	end

	if not unit:HasBullet() then
		unit.CurrentTarget = BrainActions.AcquireTarget(unit, pos)
		unit.Intent = Intent.Reload
	elseif unit.CurrentTarget then
		unit.Intent = Intent.Fire
	end
end

function BrainActions.Plan(unit)
	unit.Decision = Decision.Plan
	BattlefieldCover:FindBestNode(unit)
	if unit.AssignedCoverNode then
		BrainActions.Reposition(unit, unit.AssignedCoverNode)
	end
end

function BrainActions.TakeCover(unit)
	unit.Decision = Decision.TakeCover
	BattlefieldCover:FindNearestForwardCover(unit)
	if unit.AssignedCoverNode then
		BrainActions.Reposition(unit, unit.AssignedCoverNode)
	end
end

function BrainActions.DefendObjective(unit)
	unit.Decision = Decision.DefendObjective
	BattlefieldCover:DefendObjective(unit)
	if unit.AssignedCoverNode then
		BrainActions.Reposition(unit, unit.AssignedCoverNode)
	end
end

function BrainActions.TakeTower(unit, pos, tower)
	unit.Decision = Decision.TakeTower
	if unit.TowerPhase == TowerPhase.None then
		unit.TowerPhase = TowerPhase.ToLadder
		unit.MoveDestination = tower.Runtime.BasePosition
		unit.Intent = Intent.Move

	elseif unit.TowerPhase == TowerPhase.ToLadder then
		unit.Intent = Intent.Move
		if BrainActions.GetHorizontalDistance(tower.Runtime.BasePosition,pos) < BrainActions.ARRIVAL_RADIUS then
			unit.TowerPhase = TowerPhase.Climbing
			unit.MoveDestination = tower.Runtime.TopPosition
			unit.Intent = Intent.Climb
		end
	elseif unit.TowerPhase == TowerPhase.Climbing then
		unit.Intent = Intent.Climb
		if (unit.MoveDestination - pos).Magnitude < BrainActions.ARRIVAL_RADIUS then
			unit.TowerPhase = TowerPhase.ToCover
			unit.MoveDestination = tower.Runtime.TopPosition + tower.Runtime.SlotOffsets[unit.TowerAssignment.Slot]
			unit.Intent = Intent.Move
		end
	elseif unit.TowerPhase == TowerPhase.ToCover then
		unit.Intent = Intent.Move
		if (unit.MoveDestination - pos).Magnitude < BrainActions.ARRIVAL_RADIUS then
			unit.TowerPhase = TowerPhase.AtCover
		end
	else
		if next(unit.AvailableTargets) ~= nil then
			BrainActions.Engage(unit, pos)
		else
			BrainActions.Hold(unit)
		end
	end
end

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

function BrainActions.AcquireTarget(unit, pos)
	local bestEnemy = nil
	local bestDist = math.huge

	for enemy in pairs(unit.AvailableTargets) do
		local d = BrainActions.GetHorizontalDistance(enemy.Root.Position,pos)
		if d < bestDist then
			bestDist = d
			bestEnemy = enemy
		end
	end

	return bestEnemy
end

function BrainActions.AcquireChargeTarget(unit, pos)
	local bestEnemy = nil
	local bestDist = math.huge

	for enemy in pairs(unit.AvailableChargeTargets) do
		local d = (enemy.Root.Position - pos).Magnitude
		if d < bestDist then
			bestDist = d
			bestEnemy = enemy
		end
	end

	return bestEnemy
end

function BrainActions.GetHorizontalDistance(pos1, pos2)
	return (Vector3.new(pos1.X, 0, pos1.Z) - Vector3.new(pos2.X, 0, pos2.Z)).Magnitude
end

function BrainActions.HasCrossedMidline(unit)
	local z = unit.Root.Position.Z

	if unit.Team == "A" then
		return z <= CROSS_Z_THRESHOLD
	else
		return z >= CROSS_Z_THRESHOLD
	end
end

return BrainActions