-- InfantryBrain.lua
--
-- Stateless tactical decision module for infantry units.
--
-- RESPONSIBILITIES:
--   • Observe current UnitRuntime state and perception results
--   • Resolve the unit’s current BehaviorPhase
--   • Determine high-level Intent (Move / Fire / Reload / None)
--   • Select targets, destinations, and desired facing
--
-- NOT RESPONSIBLE FOR:
--   • Movement execution
--   • Animation playback or sequencing
--   • Firing, reload timing, or ammo manipulation
--   • Cooldowns, health, or death handling
--
-- ARCHITECTURAL RULES:
--   • InfantryBrain must be side-effect free
--   • No CFrame writes or transform manipulation
--   • No animation calls
--   • No timers or long-lived state
--
-- OUTPUT CONTRACT:
--   Brain.Update(unit, dt) may set:
--     • unit.Decision
--     • unit.Intent
--     • unit.Target / unit.MoveDestination
--
-- All outputs are advisory; execution is owned by UnitRuntime.
--
-- DESIGN GOALS:
--   • Readable, testable tactical logic
--   • Deterministic decisions given the same inputs
--   • Easy extension for new unit archetypes (snipers, commandos)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Intent = require(ReplicatedStorage.Shared.Types.Intent)
local Strategy = require(ReplicatedStorage.Shared.Types.Strategy)

local BattlefieldCover = require(script.Parent.BattlefieldCover)
local Actions = require(script.Parent.BrainActions)

local InfantryBrain = {}

function InfantryBrain.Update(unit, dt)
	if unit.Strategy == Strategy.Strategy.Blitz then
		InfantryBrain.UpdateBlitz(unit, dt)
	elseif unit.Strategy == Strategy.Strategy.Stalk then
		InfantryBrain.UpdateStalk(unit, dt)
	elseif unit.Strategy == Strategy.Strategy.Defend then
		InfantryBrain.UpdateDefend(unit, dt)
	end
end

function InfantryBrain.UpdateBlitz(unit, dt)
	local root = unit.Root
	local pos = root.Position	
	local node = unit.AssignedCoverNode
	
	if next(unit.AvailableMeleeTargets) ~= nil then
		Actions.Melee(unit)
	elseif next(unit.AvailableChargeTargets) ~= nil then
		Actions.Charge(unit, pos)		
	elseif node and node:GetDistanceFrom(pos) > Actions.ARRIVAL_RADIUS then
		Actions.Reposition(unit, node)
	elseif next(unit.TargetedBy) == nil then
		local dist = (unit.EnemyObjective.Root.Position - pos).Magnitude
		if dist <= unit.ResolvedStats.FireRange then
			Actions.Destroy(unit)
		elseif dist <= unit.ResolvedStats.VisionRange or Actions.HasCrossedMidline(unit) then
			Actions.SeekObjective(unit)
		else
			Actions.SeekAcross(unit)
		end

	elseif next(unit.AvailableTargets) ~= nil then
		if not node then
			Actions.Plan(unit)
		elseif (unit.Intent == Intent.Reload and unit:HasBullet() and BattlefieldCover:IsNodeFlanked(unit, node)) then
			Actions.Plan(unit)
		else
			Actions.Engage(unit, pos)
		end
	else
		Actions.TakeCover(unit)
	end
end

function InfantryBrain.UpdateStalk(unit, dt)
	local root = unit.Root
	local pos = root.Position
	local node = unit.AssignedCoverNode

	if next(unit.AvailableMeleeTargets) ~= nil then
		Actions.Melee(unit)
	elseif node and node:GetDistanceFrom(pos) > Actions.ARRIVAL_RADIUS then
		Actions.Reposition(unit, node)
	elseif next(unit.KnownEnemies) == nil then
		local dist = (unit.EnemyObjective.Root.Position - pos).Magnitude
		if dist <= unit.ResolvedStats.FireRange then
			Actions.Destroy(unit)
		elseif dist <= unit.ResolvedStats.VisionRange or Actions.HasCrossedMidline(unit) then
			Actions.SeekObjective(unit)
		else
			Actions.SeekAcross(unit)
		end
	elseif next(unit.AvailableTargets) ~= nil then
		if not node then
			if unit.Stealth then
				Actions.TakeCover(unit)
			else
				Actions.Plan(unit)
			end
		elseif (unit.Intent == Intent.Reload and unit:HasBullet() and BattlefieldCover:IsNodeFlanked(unit, node)) then
			Actions.Plan(unit)
		elseif next(unit.StealthFriendsMoving) ~= nil then
			Actions.Hold(unit)
		else
			Actions.Engage(unit, pos)
		end
	elseif next(unit.KnownInboundEnemies) ~= nil then
		if not node then
			Actions.TakeCover(unit)
		else
			Actions.Hold(unit)
		end
	else
		Actions.SeekEnemy(unit, pos)
	end
end

function InfantryBrain.UpdateDefend(unit, dt)
	local pos = unit.Root.Position
	local node = unit.AssignedCoverNode
	local tower = unit.TowerAssignment and unit.TowerAssignment.Tower

	if tower then
		Actions.TakeTower(unit, pos, tower)
	elseif not node then
		Actions.DefendObjective(unit)
	elseif node:GetDistanceFrom(pos) > Actions.ARRIVAL_RADIUS then
		Actions.Reposition(unit, node)
	else
		if next(unit.AvailableTargets) ~= nil then
			Actions.Engage(unit, pos)
		elseif (unit.Intent == Intent.Reload and unit:HasBullet() and BattlefieldCover:IsNodeFlanked(unit, node)) then
			Actions.Plan(unit)	
		else
			Actions.Hold(unit)
		end
	end
end

return InfantryBrain
