--[[
SniperFireController.lua

Role:
- Class-specific fire controller for Sniper.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Intent = require(ReplicatedStorage.Shared.Types.Intent)
local SniperFirePhase = require(ReplicatedStorage.Shared.Types.SniperFirePhase)
local StatResolver = require(ReplicatedStorage.Shared.Combat.StatResolver)
local HealthBarStyle = require(ReplicatedStorage.Shared.Presentation.HealthBarStyle)

local SniperFireController = {}
local AIM_WINDOW_TIME = 3.0
local LASER_THICKNESS = 0.14
local TARGET_AIM_HEIGHT_OFFSET = 4.0

local function getAimTargetPosition(target)
	if not target then
		return nil
	end

	local model = target.Model
	if model then
		local head = model:FindFirstChild("Head", true)
		if head and head:IsA("BasePart") then
			return head.Position
		end
	end

	if target.Root then
		return target.Root.Position + Vector3.new(0, TARGET_AIM_HEIGHT_OFFSET, 0)
	end

	return nil
end

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
		if state.Laser.Model then
			state.Laser.Model:Destroy()
		end
		state.Laser = nil
	end
end

local function getOrCreateLaser(state)
	if state.Laser and state.Laser.Model and state.Laser.Model.Parent then
		return state.Laser
	end

	local model = Instance.new("Model")
	model.Name = "SniperAimLaser"

	local startPart = Instance.new("Part")
	startPart.Name = "Start"
	startPart.Size = Vector3.new(0.1, 0.1, 0.1)
	startPart.Transparency = 1
	startPart.Anchored = true
	startPart.CanCollide = false
	startPart.CanQuery = false
	startPart.CanTouch = false
	startPart.Parent = model

	local endPart = Instance.new("Part")
	endPart.Name = "End"
	endPart.Size = Vector3.new(0.1, 0.1, 0.1)
	endPart.Transparency = 1
	endPart.Anchored = true
	endPart.CanCollide = false
	endPart.CanQuery = false
	endPart.CanTouch = false
	endPart.Parent = model

	local a0 = Instance.new("Attachment")
	a0.Name = "A0"
	a0.Parent = startPart

	local a1 = Instance.new("Attachment")
	a1.Name = "A1"
	a1.Parent = endPart

	local outerBeam = Instance.new("Beam")
	outerBeam.Name = "OuterBeam"
	outerBeam.Attachment0 = a0
	outerBeam.Attachment1 = a1
	outerBeam.FaceCamera = true
	outerBeam.LightEmission = 1
	outerBeam.Width0 = LASER_THICKNESS
	outerBeam.Width1 = LASER_THICKNESS
	outerBeam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0.35),
	})
	outerBeam.Parent = startPart

	local innerBeam = Instance.new("Beam")
	innerBeam.Name = "InnerBeam"
	innerBeam.Attachment0 = a0
	innerBeam.Attachment1 = a1
	innerBeam.FaceCamera = true
	innerBeam.LightEmission = 1
	innerBeam.Width0 = LASER_THICKNESS * 0.35
	innerBeam.Width1 = LASER_THICKNESS * 0.35
	innerBeam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	innerBeam.Color = ColorSequence.new(Color3.new(1, 1, 1))
	innerBeam.Parent = startPart

	model.Parent = workspace

	state.Laser = {
		Model = model,
		StartPart = startPart,
		EndPart = endPart,
		OuterBeam = outerBeam,
		InnerBeam = innerBeam,
	}

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

	local aimPos = getAimTargetPosition(target)
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
	local teamColor =
		HealthBarStyle.TeamColors[unit.Team]
		or HealthBarStyle.TeamColors.Neutral

	laser.StartPart.CFrame = CFrame.new(origin)
	laser.EndPart.CFrame = CFrame.new(aimPos)
	laser.OuterBeam.Color = ColorSequence.new(teamColor)
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
	local handle = unit.Model:FindFirstChild("Handle")
	local barrel = handle and handle:FindFirstChild("Barrel")
	local target = getAimTargetPosition(enemy)
	if not target then
		return
	end

	local fireOrigin = unit.Root.Position
	if barrel then
		fireOrigin = barrel.WorldPosition

		local muzzle = barrel:FindFirstChild("MuzzleFlash")
		local light = barrel:FindFirstChild("PointLight")

		if muzzle then
			muzzle:Emit(12)
		end

		if light then
			light.Enabled = true
			task.delay(0.05, function()
				if light then
					light.Enabled = false
				end
			end)
		end
	end

	local bullet = Instance.new("Part")
	bullet.Size = Vector3.new(0.08, 0.08, 3.0)
	bullet.Material = Enum.Material.Neon
	bullet.Color = Color3.fromRGB(255, 170, 60)
	bullet.Transparency = 0.15
	bullet.CanCollide = false
	bullet.Anchored = true
	bullet.Parent = workspace

	local dir = target - fireOrigin
	local distance = dir.Magnitude
	if distance <= 0 then
		bullet:Destroy()
		return
	end

	local direction = dir.Unit
	bullet.CFrame = CFrame.new(fireOrigin, fireOrigin + direction)

	local travelTime = 0.08
	local startTime = time()

	local RunService = game:GetService("RunService")
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = (time() - startTime) / travelTime
		if t >= 1 then
			bullet:Destroy()
			conn:Disconnect()
			return
		end

		local pos = fireOrigin + direction * distance * t
		bullet.CFrame = CFrame.new(pos, pos + direction)
		bullet.Transparency = 0.15 + 0.85 * t
	end)
end

function SniperFireController:OnUnitDied(unit)
	local state = unit.SniperFireState
	if not state then
		return
	end

	destroyLaser(state)
end

return SniperFireController
