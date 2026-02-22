-- BattlefieldCover.lua
--
-- Authoritative tactical map representation.
--
-- This module defines:
--   • All cover nodes on the battlefield
--   • How good each node is for a given unit
--   • Flanking, protection, and pressure rules
--   • Occupancy & reservation logic
--
-- AI brains query this module but never re-implement geometry or cover rules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoverNode = require(script.Parent.CoverNode)
local GridUtil =require(ReplicatedStorage.Shared.Util.GridUtil)
local Helpers = require(ReplicatedStorage.Shared.Util.Helpers)

local BattlefieldCover = {}

local DebugState = game.ReplicatedStorage
	:WaitForChild("State")
	:WaitForChild("DebugStateValue")
	.Value

function BattlefieldCover:UpdateNodeDebugColor(unit, node)
	if not DebugState then return end
	if not node.DebugPart then return end

	if self:GetReservationCount(node) > 0 then
		node.DebugPart.Color = Color3.fromRGB(0, 0, 255)
	else
		node.DebugPart.Color = Color3.fromRGB(255, 255, 255)
	end

	if self:IsNodeFlanked(unit, node) then
		node.DebugPart.Color = Color3.fromRGB(255, 0, 0)
	end

	if node.DebugLabel then
		if node.DebugScore ~= nil then
			node.DebugLabel.Text = string.format("%.0f", node.DebugScore)

			local t = math.clamp((node.DebugScore + 2000) / 2000, 0, 1)

			local r = math.floor(255 * (1 - t))
			local g = math.floor(255 * t)

			node.DebugLabel.TextColor3 = Color3.fromRGB(r, g, 0)
		else
			node.DebugLabel.Text = ""
		end
	end
end

BattlefieldCover.WALL_FORWARD_OFFSET = 1.5

local GRID_SPACING = 30
local JITTER_RADIUS = 6
local COVER_OBJECT_DENSITY = 1 / 600

BattlefieldCover.Nodes = {}

local COVER_AREA = {
	RowMin = 2,
	RowMax = GridUtil.GRID_SIZE - 1,
	ColMin = 1,
	ColMax = GridUtil.GRID_SIZE,
}

local function generateAreaCover()
	local objects = {}

	local minPos, maxPos = GridUtil.GetBoundsOfArea(
		COVER_AREA.RowMin,
		COVER_AREA.RowMax,
		COVER_AREA.ColMin,
		COVER_AREA.ColMax
	)
	
	local halfCell = (GridUtil.MAP_SIZE / GridUtil.GRID_SIZE) / 2 - 8
	local minX, maxX = minPos.X, maxPos.X
	local minZ, maxZ = minPos.Z - halfCell, maxPos.Z + halfCell
	local areaSize = (maxX - minX) * (maxZ - minZ)
	local targetCount = math.floor(areaSize * COVER_OBJECT_DENSITY)
	local minDistance = 12
	local attempts = 0
	local maxAttempts = targetCount * 20

	while #objects < targetCount and attempts < maxAttempts do
		attempts += 1

		local pos = Vector3.new(
			math.random() * (maxX - minX) + minX,
			0,
			math.random() * (maxZ - minZ) + minZ
		)

		local valid = true
		for _, obj in ipairs(objects) do
			if (obj.Position - pos).Magnitude < minDistance then
				valid = false
				break
			end
		end

		if valid then
			local shape = (math.random() < 0.6) and "Rect" or "Square"
			local yaw = math.random() * math.pi * 2

			table.insert(objects, {
				Id = "Cover_" .. #objects + 1,
				Shape = shape,
				Position = pos,
				Rotation = yaw,
			})
		end
	end

	return objects
end


local function createRectangularNodes(obj)
	local nodes = {}

	local wallDir = Vector3.new(
		math.sin(obj.Rotation),
		0,
		math.cos(obj.Rotation)
	).Unit

	local normal = Vector3.new(-wallDir.Z, 0, wallDir.X)
	local sides = {
		normal,
		-normal,
	}

	for i, side in ipairs(sides) do
		table.insert(nodes, CoverNode.new(
			obj.Id .. "_" .. i,
			obj.Position + side * BattlefieldCover.WALL_FORWARD_OFFSET,
			-side,
			1
			))
	end

	return nodes
end


local function createSquareNodes(obj)
	local nodes = {}
	local HALF_EXTENT = 3

	local directions = {
		Vector3.new( 1, 0,  0),
		Vector3.new(-1, 0,  0),
		Vector3.new( 0, 0,  1),
		Vector3.new( 0, 0, -1),
	}

	for i, dir in ipairs(directions) do
		local rotated =
			CFrame.fromAxisAngle(Vector3.yAxis, obj.Rotation)
			:VectorToWorldSpace(dir)

		local pos = obj.Position + rotated * HALF_EXTENT
		local forward = -rotated

		table.insert(nodes, CoverNode.new(
			obj.Id .. "_" .. i,
			pos,
			forward,
			1
			))
	end

	return nodes
end

function BattlefieldCover:PrecomputeNodeDistances(maxDistance)

	local maxDistSq = maxDistance * maxDistance
	local nodes = self.Nodes
	local count = #nodes

	for i = 1, count do
		local a = nodes[i]

		a.DistanceMap = {}
		a.DistanceList = {}

		for j = 1, count do
			if i ~= j then
				local b = nodes[j]

				local delta = b.Position - a.Position
				local distSq = delta:Dot(delta)

				if distSq <= maxDistSq then
					a.DistanceMap[b] = distSq

					table.insert(a.DistanceList, {
						Node = b,
						DistSq = distSq,
					})
				end
			end
		end

		table.sort(a.DistanceList, function(x, y)
			return x.DistSq < y.DistSq
		end)
	end
end


BattlefieldCover.Nodes = {}

for _, obj in ipairs(generateAreaCover()) do
	local nodes

	if obj.Shape == "Rect" then
		nodes = createRectangularNodes(obj)
	else
		nodes = createSquareNodes(obj)
	end

	for _, node in ipairs(nodes) do
		table.insert(BattlefieldCover.Nodes, node)
	end
end

BattlefieldCover:PrecomputeNodeDistances(200 * 200)

local INCOMING_FIRE_PENALTY = 300
local DISTANCE_RISK_WEIGHT = 200
local ADJACENT_CLUSTER_DIST = math.sqrt(GRID_SPACING * GRID_SPACING * 2) + (JITTER_RADIUS * 2)
local FLANK_BONUS = ADJACENT_CLUSTER_DIST * DISTANCE_RISK_WEIGHT 

function BattlefieldCover:ScoreNode(unit, node)
	local score = 0

	if self:NodeFlanksEnemy(unit, node) then
		score += (FLANK_BONUS / unit.ResolvedStats.MoveSpeed) + INCOMING_FIRE_PENALTY + 100
	end

	local incoming = self:CountEnemiesThatCanShootNode(unit, node)
	score -= incoming * INCOMING_FIRE_PENALTY

	local distancePenalty = (node.Position - unit.Root.Position).Magnitude * (#unit.TargetedBy + 1) * (DISTANCE_RISK_WEIGHT / unit.ResolvedStats.MoveSpeed)
	
	if node ~= unit.AssignedCoverNode then
		score -= distancePenalty
	end
	
	if DebugState then
		node.DebugScore = score
	end
	
	return score
end

---------------------------------------------------------------------
-- Tiered classification
---------------------------------------------------------------------

function BattlefieldCover:ClassifyNode(unit, node)
	local flanked = self:IsNodeFlanked(unit, node)
	local canShoot = self:NodeCanShoot(unit, node)

	if not flanked and canShoot then
		return 1
	elseif not flanked then
		return 2
	elseif canShoot then
		return 3
	else
		return 4
	end
end

function BattlefieldCover:FindBestNode(unit)
	local bestTier = math.huge
	local candidates = {}

	for _, node in ipairs(self.Nodes) do
		if self:HasFreeSlot(node) or node == unit.AssignedCoverNode then
			local tier = self:ClassifyNode(unit, node)

			if tier < bestTier then
				bestTier = tier
				candidates = { node }
			elseif tier == bestTier then
				table.insert(candidates, node)
			end
		end
		self:UpdateNodeDebugColor(unit,node)
	end

	local bestNode = nil
	local bestScore = -math.huge

	for _, node in ipairs(candidates) do
		local score = self:ScoreNode(unit, node)
		if score > bestScore then
			bestScore = score
			bestNode = node
		end
	end

	self:SetUnitNode(unit, bestNode)
end

function BattlefieldCover:FindNearestForwardCover(unit)
	local unitPos = unit.Root.Position
	local unitForward = unit.Root.CFrame.LookVector
	local bestNode = nil
	local bestDistSq = math.huge

	for _, node in ipairs(self.Nodes) do
		if self:HasFreeSlot(node) or node == unit.AssignedCoverNode then
			local toCover = node.Position - unitPos
			local distSq = toCover:Dot(toCover)
			local unitFacingNode = Helpers.IsFacing(unitPos,unitForward,node.Position)
			local nodeFacingOut = Helpers.IsFacing(node.Position,node.Forward,node.Position + toCover)

			if unitFacingNode and nodeFacingOut and distSq < bestDistSq then
				bestDistSq = distSq
				bestNode = node
			end
		end
	end

	self:SetUnitNode(unit, bestNode)
end


function BattlefieldCover:DefendObjective(unit)

	local objective = unit.FriendlyObjective
	local unitPos = unit.Root.Position
	local objectivePos = objective.Root.Position
	local objectiveForward = objective.Root.CFrame.LookVector
	local bestNode = nil
	local bestDistSq = math.huge

	for _, node in ipairs(self.Nodes) do
		if self:HasFreeSlot(node) and node:GetDistanceFrom(objectivePos) <= unit.ResolvedStats.FireRange then
			local toCover = node.Position - unitPos
			local distSq = toCover:Dot(toCover)
			local nodeAlignedWithObjective = node.Forward:Dot(objectiveForward) >= 0
			
			if nodeAlignedWithObjective and distSq < bestDistSq then
				bestDistSq = distSq
				bestNode = node
			end
		end
	end

	self:SetUnitNode(unit, bestNode)
end

function BattlefieldCover:AttackObjective(unit)

	local objective = unit.EnemyObjective
	local unitPos = unit.Root.Position
	local objectivePos = objective.Root.Position
	local objectiveForward = objective.Root.CFrame.LookVector
	local bestNode = nil
	local bestDistSq = math.huge

	for _, node in ipairs(self.Nodes) do
		if self:HasFreeSlot(node) and node:GetDistanceFrom(objectivePos) <= unit.ResolvedStats.FireRange then
			local toCover = node.Position - unitPos
			local distSq = toCover:Dot(toCover)
			local nodeFacingObjectiveForward = Helpers.IsFacing(node.Position,-node.Forward,objectivePos)
			
			if not nodeFacingObjectiveForward and distSq < bestDistSq then
				bestDistSq = distSq
				bestNode = node
			end
		end
	end
	self:SetUnitNode(unit, bestNode)
end

---------------------------------------------------------------------
-- Geometry queries
---------------------------------------------------------------------

function BattlefieldCover:NodeCanShoot(unit, node)
	local fireRangeSq = unit.ResolvedStats.FireRange * unit.ResolvedStats.FireRange
	for enemy in pairs(unit.KnownEnemies) do
		local enemyNode = enemy.AssignedCoverNode
		if enemyNode then
			local distSq = node.DistanceMap[enemyNode]
			if distSq and distSq <= fireRangeSq then
				return true
			end
		end
		if enemy.TowerAssignment and enemy.TowerAssignment.Tower then
			local dist = (node.Position - enemy.Root.Position).Magnitude
			if dist <= unit.ResolvedStats.FireRange then
				return true
			end
		end
	end
	return false
end

function BattlefieldCover:IsNodeFlanked(unit, node)
	for enemy in pairs(unit.KnownEnemies) do
		local enemyNode = enemy.AssignedCoverNode
		if enemyNode then
			local distSq = node.DistanceMap[enemyNode]
			if distSq then
				local fireRange = enemy.ResolvedStats.FireRange
				if distSq <= fireRange * fireRange then
					local nodeFacingEnemy = Helpers.IsFacing(node.Position, node.Forward, enemyNode.Position)
					if not nodeFacingEnemy then
						return true
					end
				end
			end
		end
		if enemy.TowerAssignment and enemy.TowerAssignment.Tower then
			local dist = (node.Position - enemy.TowerAssignment.Tower.TopPosition).Magnitude
			if dist <= enemy.ResolvedStats.FireRange and not Helpers.IsFacing(node.Position, node.Forward, enemy.TowerAssignment.Tower.TopPosition) then
				return true
			end
		end
	end
	return false
end

function BattlefieldCover:NodeFlanksEnemy(unit, node)
	local fireRangeSq = unit.ResolvedStats.FireRange * unit.ResolvedStats.FireRange
	for enemy in pairs(unit.KnownEnemies) do
		local enemyNode = enemy.AssignedCoverNode
		if enemyNode then
			local enemyFacingUs = Helpers.IsFacing(enemyNode.Position,enemyNode.Forward,node.Position)
			if not enemyFacingUs then
				local distSq = node.DistanceMap[enemyNode]
				if distSq and distSq <= fireRangeSq then
					return true
				end
			end
		end
	end
	return false
end

function BattlefieldCover:CountEnemiesThatCanShootNode(unit, node)
	local count = 0
	for enemy in pairs(unit.KnownEnemies) do
		local enemyNode = enemy.AssignedCoverNode
		if enemyNode then
			local distSq = node.DistanceMap[enemyNode]
			if distSq then
				local fireRange = enemy.ResolvedStats.FireRange
				if distSq <= fireRange * fireRange then
					count += 1
				end
			end
		end
		if enemy.TowerAssignment and enemy.TowerAssignment.Tower then
			local dist = (node.Position - enemy.Root.Position).Magnitude
			if dist <= enemy.ResolvedStats.FireRange then
				count += 1
			end
		end
	end
	return count
end

---------------------------------------------------------------------
-- Occupancy management
---------------------------------------------------------------------

function BattlefieldCover:SetUnitNode(unit, node)
	if node then
		local assigned = unit.AssignedCoverNode

		if assigned then
			assigned.Reserved[unit] = nil
			self:UpdateNodeDebugColor(unit, assigned)
		end		
		
		node.Reserved[unit] = true
		unit.AssignedCoverNode = node
		self:UpdateNodeDebugColor(unit, node)
	end
end

function BattlefieldCover:UnReserve(unit)
	local assignedNode = unit.AssignedCoverNode
	if assignedNode then
		assignedNode.Reserved[unit] = nil
		self:UpdateNodeDebugColor(unit, assignedNode)
		unit.AssignedCoverNode = nil
	end
end

function BattlefieldCover:HasFreeSlot(node)
	local reservations = self:GetReservationCount(node)
	return reservations < node.Slots
end

function BattlefieldCover:GetReservationCount(node)
	local n = 0
	for _ in pairs(node.Reserved) do
		n += 1
	end
	return n
end

return BattlefieldCover