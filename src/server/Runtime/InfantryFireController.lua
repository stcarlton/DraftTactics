--[[
InfantryFireController.lua

Role:
- Class-specific fire controller for Infantry.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatResolver = require(ReplicatedStorage.Shared.Combat.StatResolver)

local InfantryFireController = {}

function InfantryFireController:Tick(unit, dt)
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

return InfantryFireController
