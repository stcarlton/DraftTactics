--[[
InfantryFireController.lua

Role:
- Class-specific fire controller for Infantry.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Intent = require(ReplicatedStorage.Shared.Types.Intent)
local StatResolver = require(ReplicatedStorage.Shared.Combat.StatResolver)
local BattleVFX = require(script.Parent.BattleVFX)

local InfantryFireController = {}

function InfantryFireController:Tick(unit, dt)
	if unit.Intent ~= Intent.Fire then
		return
	end

	unit.FireCooldown -= dt
	if unit.FireCooldown <= 0 then
		self:Fire(unit)
	end

	if unit.Stealth then
		unit.AmbushTime -= dt
		if unit.AmbushTime <= 0 then
			unit.Stealth = false
		end
	end
end

function InfantryFireController:Fire(unit)
	local enemy = unit.CurrentTarget
	if not enemy or not enemy.IsAlive then
		return
	end

	self:DrawTracer(unit)
	StatResolver.ResolveRanged(unit, enemy)

	if unit.SharedState.PreEngagement then
		unit.SharedState.PreEngagement = false
	end

	unit.AmmoInMag -= 1
	unit.FireCooldown = 1 / unit.ResolvedStats.FireRate
	if unit.VisualEvents then
		unit.VisualEvents.Fired = true
	end
end

function InfantryFireController:DrawTracer(unit)
	local target = unit.CurrentTarget.Root.Position
	local fireOrigin = BattleVFX.EmitMuzzle(unit)
	BattleVFX.DrawTracer(fireOrigin, target)
end

return InfantryFireController
