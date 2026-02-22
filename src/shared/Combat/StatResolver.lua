-- StatResolver.lua
--
-- Pure combat rules engine.
-- No AI logic.
-- No animation control.
-- No state orchestration.
--
-- Responsible only for:
--   • Gathering modifiers
--   • Applying stat changes
--   • Applying RNG variance
--   • Applying damage
--   • Returning structured result

local ModifierStack = require(script.Parent.ModifierStack)
local UnitModifiers = require(script.Parent.UnitModifiers)
local Intent = require(game.ReplicatedStorage.Shared.Types.Intent)
local Decision = require(game.ReplicatedStorage.Shared.Types.Decision)

local StatResolver = {}

function StatResolver.UnitIsFlankedBy(attacker, defender)
	local defenderNode = defender.AssignedCoverNode
	if defender.TowerAssignment then
		return false
	elseif defender.Decision == Decision.Charge then
		return false
	elseif attacker.Stealth then
		return false
	elseif defenderNode and defender.Intent ~= Intent.Move then
		local toAttacker = (attacker.Root.Position - defenderNode.Position).Unit
		return defenderNode.Forward:Dot(toAttacker) < 0
	else
		return true
	end
end

function StatResolver.GetInitialStats(unit)
	local stack = ModifierStack.new()
	UnitModifiers.ApplyStaticModifiers(unit, stack)
	return stack:ApplyTo(unit.Config)
end

function StatResolver.GetUnitStats(unit)
	local stack = ModifierStack.new()
	UnitModifiers.ApplyRuntimeModifiers(unit, stack)
	return stack:ApplyTo(unit.Config)
end

function StatResolver.ResolveRanged(attacker, defender)
	local damage = attacker.ResolvedStats.Damage
	local damageReduction = defender.ResolvedStats.DamageReduction
	if not StatResolver.UnitIsFlankedBy(attacker, defender) then
		damageReduction += defender.ResolvedStats.CoverReduction
	end
	damage = damage * (1 - damageReduction)
	defender:TakeDamage(damage)
end

function StatResolver.ResolveMelee(attacker, defender)
	local damage = attacker.ResolvedStats.MeleeDamage
	local damageReduction = defender.ResolvedStats.DamageReduction
	damage = damage * (1 - damageReduction)
	defender:TakeDamage(damage)
end

return StatResolver
