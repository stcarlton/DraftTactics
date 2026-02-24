--[[
SniperFireController.lua

Role:
- Class-specific fire controller for Sniper.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Intent = require(ReplicatedStorage.Shared.Types.Intent)
local SniperFirePhase = require(ReplicatedStorage.Shared.Types.SniperFirePhase)
local StatResolver = require(ReplicatedStorage.Shared.Combat.StatResolver)
local BattleVFX = require(script.Parent.BattleVFX)

local SniperFireController = {}
local AIM_WINDOW_TIME = 3.0
-- Intentionally exaggerated for distance-visibility/aliasing diagnosis.
local LASER_THICKNESS = 0.4
local SNIPER_TRACER_OPTIONS = {
	Size = Vector3.new(0.28, 0.28, 56.0),
	Color = Color3.fromRGB(255, 245, 210),
	StartTransparency = 0,
	EndTransparency = 1,
	TravelTime = 0.08,
}

local function getState(unit)
	local state = unit.SniperFireState
	if state then
		return state
	end

	state = {
		Phase = SniperFirePhase.Idle,
		AimTimer = 0,
		LockedTarget = nil,
		Laser = nil,
	}

	unit.SniperFireState = state
	return state
end

local function destroyLaser(state)
	if state.Laser then
		BattleVFX.DestroyLaser(state.Laser)
		state.Laser = nil
	end
end

local function getOrCreateLaser(state)
	if state.Laser and state.Laser.Model and state.Laser.Model.Parent then
		return state.Laser
	end

	state.Laser = BattleVFX.CreateSniperAimLaser()
	return state.Laser
end

local function updateLaser(state, unit, target)
	if not target or not target.IsAlive then
		destroyLaser(state)
		return
	end

	local handle = unit.Model:FindFirstChild("Handle")
	local barrel = handle and handle:FindFirstChild("Barrel")
	local origin = unit.Root.Position
	if barrel then
		origin = barrel.WorldPosition
	end

	local aimPos = BattleVFX.GetAimTargetPosition(target)
	if not aimPos then
		destroyLaser(state)
		return
	end
	local dir = aimPos - origin
	local distance = dir.Magnitude
	if distance <= 0 then
		destroyLaser(state)
		return
	end

	local laser = getOrCreateLaser(state)
	BattleVFX.UpdateSniperAimLaser(laser, origin, aimPos, unit.Team, LASER_THICKNESS)
end

local function clearAim(state)
	state.Phase = SniperFirePhase.Idle
	state.AimTimer = 0
	state.LockedTarget = nil
	destroyLaser(state)
end

local function beginAim(state, unit, target)
	state.Phase = SniperFirePhase.Aiming
	state.AimTimer = AIM_WINDOW_TIME
	state.LockedTarget = target
	updateLaser(state, unit, target)
end

function SniperFireController:Tick(unit, dt)
	local state = getState(unit)

	if unit.Intent ~= Intent.Fire then
		if state.Phase == SniperFirePhase.Aiming then
			clearAim(state)
		end
		return
	end

	if unit.Stealth then
		unit.AmbushTime -= dt
		if unit.AmbushTime <= 0 then
			unit.Stealth = false
		end
	end

	if state.Phase == SniperFirePhase.CoolDown then
		unit.FireCooldown -= dt
		if unit.FireCooldown > 0 then
			return
		end

		unit.FireCooldown = 0
		state.Phase = SniperFirePhase.Idle
	end

	local target = unit.CurrentTarget
	if not target or not target.IsAlive then
		if state.Phase == SniperFirePhase.Aiming then
			-- Preserve aim progress while waiting for the brain to pick a new target.
			state.LockedTarget = nil
			destroyLaser(state)
		end
		return
	end

	if state.Phase == SniperFirePhase.Idle then
		beginAim(state, unit, target)
	end

	if state.Phase == SniperFirePhase.Aiming then
		if state.LockedTarget ~= target then
			-- Retarget without resetting aim progress.
			state.LockedTarget = target
		end

		updateLaser(state, unit, state.LockedTarget)
		state.AimTimer -= dt

		if state.AimTimer <= 0 then
			self:Fire(unit, state)
		end
	end
end

function SniperFireController:Fire(unit, state)
	local enemy = state and state.LockedTarget or unit.CurrentTarget
	if not enemy or not enemy.IsAlive then
		if state then
			clearAim(state)
		end
		return
	end

	self:DrawTracer(unit, enemy)
	StatResolver.ResolveRanged(unit, enemy)

	if unit.SharedState.PreEngagement then
		unit.SharedState.PreEngagement = false
	end

	unit.AmmoInMag -= 1
	unit.FireCooldown = 1 / unit.ResolvedStats.FireRate
	if unit.VisualEvents then
		unit.VisualEvents.Fired = true
	end

	if state then
		destroyLaser(state)
		state.LockedTarget = nil
		state.AimTimer = 0
		state.Phase = SniperFirePhase.CoolDown
	end
end

function SniperFireController:DrawTracer(unit, enemy)
	local target = BattleVFX.GetAimTargetPosition(enemy)
	if not target then
		return
	end

	local fireOrigin = BattleVFX.EmitMuzzle(unit)
	BattleVFX.DrawTracer(fireOrigin, target, SNIPER_TRACER_OPTIONS)
end

function SniperFireController:OnUnitDied(unit)
	local state = unit.SniperFireState
	if not state then
		return
	end

	destroyLaser(state)
end

return SniperFireController
