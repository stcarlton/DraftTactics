--[[
FireController.lua

Role:
- Executes ranged attacks.
- Handles fire cadence and shot timing.

Owns:
- Fire cooldown tracking.
- Shot validation.
- Visual shot effects trigger.

Does NOT:
- Choose targets (Brain).
- Decide intent (UnitRuntime).
- Compute damage math (StatResolver).
- Move the character.

Rules:
- Damage applied only via StatResolver.
- Deterministic timing.
- No direct mutation of other unit state.

Used By:
- UnitRuntime
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatResolver = require(ReplicatedStorage.Shared.Combat.StatResolver)
local Class = require(ReplicatedStorage.Shared.Types.Class)

local FireController = {}

FireController.TickFire = {
	[Class.Infantry] = function(unit, dt)
		unit.FireCooldown -= dt
		if unit.FireCooldown <= 0 then
			unit.Anims.StandIdle:Stop()
			unit.Anims.Run:Stop()			
			unit.Anims.Fire:Play()
			FireController.Fire(unit)
		elseif not unit.Anims.Fire.IsPlaying then
			unit.Anims.StandIdle:Play()
		end
		if unit.Stealth then
			unit.AmbushTime -= dt
			if unit.AmbushTime <= 0 then
				unit.Stealth = false
			end
		end
	end,
	[Class.Sniper] = function(unit, dt)
		unit.FireCooldown -= dt
		if unit.FireCooldown <= 0 then
			unit.Anims.StandIdle:Stop()
			unit.Anims.Run:Stop()			
			unit.Anims.Fire:Play()
			FireController.Fire(unit)

		elseif not unit.Anims.Fire.IsPlaying then
			unit.Anims.StandIdle:Play()
		end
		if unit.Stealth then
			unit.AmbushTime -= dt
			if unit.AmbushTime <= 0 then
				unit.Stealth = false
			end
		end
	end,
}

function FireController.Fire(unit)
	local enemy = unit.CurrentTarget
	if not enemy or not enemy.IsAlive then return end

	FireController.DrawTracer(unit)
	StatResolver.ResolveRanged(unit,enemy)

	if unit.SharedState.PreEngagement then
		unit.SharedState.PreEngagement = false
	end

	unit.AmmoInMag -= 1
	unit.FireCooldown = 1 / unit.ResolvedStats.FireRate
end

function FireController.DrawTracer(unit)
	local handle = unit.Model:FindFirstChild("Handle")
	local barrel = handle and handle:FindFirstChild("Barrel")
	local target = unit.CurrentTarget.Root.Position

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

function FireController.DrawShot(unit)
	local handle = unit.Model:FindFirstChild("Handle")
	local target = unit.CurrentTarget.Root.Position
	local barrel = handle and handle:FindFirstChild("Barrel")
	local fireOrigin = barrel.WorldPosition

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

	local bullet = Instance.new("Part")
	bullet.Size = Vector3.new(0.12, 0.12, 0.12)
	bullet.Transparency = 1
	bullet.CanCollide = false
	bullet.Anchored = true
	bullet.CFrame = CFrame.new(fireOrigin)
	bullet.Parent = workspace

	local dir = target - fireOrigin
	local distance = dir.Magnitude
	if distance < 0.01 then
		bullet:Destroy()
		return
	end

	local direction = dir.Unit

	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0, -1.5)
	a0.Parent = bullet

	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 0, 1.5)
	a1.Parent = bullet

	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.FaceCamera = true
	trail.Lifetime = 0.15
	trail.LightEmission = 1
	trail.WidthScale = NumberSequence.new(0.1)
	trail.Color = ColorSequence.new(
		Color3.fromRGB(255, 190, 90),
		Color3.fromRGB(255, 120, 40)
	)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Parent = bullet

	local travelTime = 0.05
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
	end)
end

return FireController
