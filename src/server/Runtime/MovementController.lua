--[[
MovementController.lua

Role:
- Executes all character locomotion.
- Applies movement and facing.
- Only file allowed to write Root.CFrame.

Owns:
- Position interpolation.
- Rotation / facing alignment.
- Movement speed application.

Does NOT:
- Decide destinations (Brain).
- Own intent (UnitRuntime).
- Perform pathfinding.
- Modify stats.
- Apply damage.

Invariants:
- Sole authority over Root.CFrame.
- No physics-driven locomotion.
- Deterministic movement per frame.
- Must not fight animation system.

Collaborators:
- UnitRuntime (provides intent + destination)
- Brain (indirectly, via runtime)
]]

local BattlefieldCover = require(script.Parent.BattlefieldCover)

local MovementController = {}

local function safeUnit(v)
	local m = v.Magnitude
	if m <= 1e-6 then return nil end
	return v / m
end

function MovementController:MoveUnit(unit, dt)
	local root = unit.Root
	local pos = root.Position
	local targetPos = unit.MoveDestination

	local toTarget = Vector3.new(targetPos.X - pos.X, 0, targetPos.Z - pos.Z)
	local forwardDir = safeUnit(toTarget)
	if not forwardDir then
		return
	end

	local moveDir = forwardDir

	for _, node in ipairs(BattlefieldCover.Nodes) do
		local toUnit = pos - node.Position

		if toUnit:Dot(node.Forward) > 0 then
			local dist = toUnit.Magnitude
			local WALL_RADIUS = 15

			if dist < WALL_RADIUS then
				local along = (node.Forward:Cross(Vector3.yAxis)).Unit
				local strength = (WALL_RADIUS - dist) / WALL_RADIUS

				if toUnit:Dot(along) < 0 then
					along = -along
				end

				moveDir += along * strength * 0.8
			end
		end
	end

	local finalDir = safeUnit(moveDir)
	if not finalDir then return end
	
	local step = unit.ResolvedStats.MoveSpeed * dt
	local newPos = pos + finalDir * step
	newPos = Vector3.new(newPos.X, pos.Y, newPos.Z)

	local baseCF = CFrame.new(newPos, newPos + finalDir)

	root.CFrame = baseCF
	
end

function MovementController:ClimbUnit(unit, dt)
	local root = unit.Root
	local pos = root.Position
	local targetPos = unit.MoveDestination
	if not targetPos then
		return
	end

	local toTarget = targetPos - pos
	local dist = toTarget.Magnitude
	if dist <= 1e-3 then
		return
	end

	local dir = toTarget / dist

	local speed = unit.ResolvedStats.ClimbSpeed
	local step = speed * dt
	if step > dist then
		step = dist
	end

	local newPos = pos + dir * step

	local currentCF = root.CFrame
	local rotationOnly = currentCF - currentCF.Position

	root.CFrame = rotationOnly + newPos
end

function MovementController:Face(unit)

	local pos = unit.Root.Position
	local tpos = unit.EnemyObjective.Root.Position
	if unit.CurrentTarget then
		tpos = unit.CurrentTarget.Root.Position
	end

	local look = Vector3.new(tpos.X - pos.X, 0, tpos.Z - pos.Z)

	if look.Magnitude > 0.01 then
		unit.Root.CFrame = CFrame.new(pos, pos + look.Unit)
	end
end

return MovementController
