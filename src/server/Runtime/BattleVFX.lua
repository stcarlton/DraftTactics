--[[
BattleVFX.lua

Role:
- Owns runtime battle visual effects (tracers, lasers, explosions, etc.).
- Purely visual. Must not affect deterministic simulation state.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local HealthBarStyle = require(ReplicatedStorage.Shared.Presentation.HealthBarStyle)

local BattleVFX = {}

local DEFAULT_TARGET_AIM_HEIGHT_OFFSET = 4.0

function BattleVFX.GetAimTargetPosition(target, heightOffset)
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
		return target.Root.Position + Vector3.new(0, heightOffset or DEFAULT_TARGET_AIM_HEIGHT_OFFSET, 0)
	end

	return nil
end

function BattleVFX.EmitMuzzle(unit)
	local handle = unit.Model:FindFirstChild("Handle")
	local barrel = handle and handle:FindFirstChild("Barrel")
	if not barrel then
		return unit.Root.Position
	end

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

	return barrel.WorldPosition
end

function BattleVFX.DrawTracer(origin, targetPos, options)
	local opts = options or {}

	local bullet = Instance.new("Part")
	bullet.Size = opts.Size or Vector3.new(0.08, 0.08, 3.0)
	bullet.Material = opts.Material or Enum.Material.Neon
	bullet.Color = opts.Color or Color3.fromRGB(255, 170, 60)
	bullet.Transparency = opts.StartTransparency or 0.15
	bullet.CanCollide = false
	bullet.CanQuery = false
	bullet.CanTouch = false
	bullet.Anchored = true
	bullet.Parent = workspace

	local dir = targetPos - origin
	local distance = dir.Magnitude
	if distance <= 0 then
		bullet:Destroy()
		return
	end

	local direction = dir.Unit
	bullet.CFrame = CFrame.new(origin, origin + direction)

	local travelTime = opts.TravelTime or 0.08
	local startTime = time()

	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = (time() - startTime) / travelTime
		if t >= 1 then
			bullet:Destroy()
			conn:Disconnect()
			return
		end

		local pos = origin + direction * distance * t
		bullet.CFrame = CFrame.new(pos, pos + direction)

		local startTransparency = opts.StartTransparency or 0.15
		local endTransparency = opts.EndTransparency or 1
		bullet.Transparency = startTransparency + (endTransparency - startTransparency) * t
	end)
end

function BattleVFX.CreateSniperAimLaser()
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

	local line = Instance.new("Part")
	line.Name = "Line"
	line.Anchored = true
	line.CanCollide = false
	line.CanQuery = false
	line.CanTouch = false
	line.CastShadow = false
	line.Material = Enum.Material.Neon
	line.Color = Color3.new(1, 1, 1)
	line.Transparency = 0.80
	line.Parent = model

	model.Parent = workspace

	return {
		Model = model,
		StartPart = startPart,
		EndPart = endPart,
		Line = line,
	}
end

function BattleVFX.DestroyLaser(laser)
	if laser and laser.Model then
		laser.Model:Destroy()
	end
end

function BattleVFX.UpdateSniperAimLaser(laser, origin, aimPos, teamId, thickness)
	local width = thickness or 0.14
	local teamColor =
		HealthBarStyle.TeamColors[teamId]
		or HealthBarStyle.TeamColors.Neutral

	laser.StartPart.CFrame = CFrame.new(origin)
	laser.EndPart.CFrame = CFrame.new(aimPos)

	local dir = aimPos - origin
	local distance = dir.Magnitude
	if distance <= 0 then
		laser.Line.Size = Vector3.new(width, width, 0.05)
		laser.Line.CFrame = CFrame.new(origin)
		return
	end

	local lineThickness = width * 0.8
	local center = origin + (dir * 0.5)
	laser.Line.Size = Vector3.new(lineThickness, lineThickness, distance)
	laser.Line.CFrame = CFrame.new(center, aimPos)
	laser.Line.Color = teamColor:Lerp(Color3.new(1, 1, 1), 0.15)
end

return BattleVFX
