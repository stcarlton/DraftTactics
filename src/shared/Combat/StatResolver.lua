--[[
StatResolver.lua

Role:
- Pure combat math engine.
- Resolves damage and final stat values.
- Applies ModifierStack to base stats.

Owns:
- Damage calculation.
- Stat aggregation logic.
- Modifier application order.

Does NOT:
- Mutate unit runtime state.
- Trigger animations or effects.
- Decide targeting.
- Manage cooldowns or ammo.

Invariants:
- Pure functions only.
- No side effects.
- Deterministic for identical inputs.
- Modifier order must remain stable.

Collaborators:
- ModifierStack
- UnitModifiers
- UnitRuntime (caller only)
]]

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
