-- CoverNode.lua
--
-- A CoverNode represents a discrete tactical position on the battlefield.
-- Units must occupy a CoverNode in order to fire.
--
-- IMPORTANT INVARIANTS:
-- - Infantry cannot fire unless occupying a CoverNode
-- - Cover provides protection only in the forward-facing 180° arc
-- - If flanked (attacker behind forward arc), cover provides NO benefit
-- - CoverNodes are authored; no runtime generation in MVP
--
-- This module defines the data contract only.
-- No behavior, queries, or AI logic live here.

local CoverNode = {}
CoverNode.__index = CoverNode

local DebugState = game.ReplicatedStorage
	:WaitForChild("State")
	:WaitForChild("DebugStateValue")
	.Value

function CoverNode.new(id, position, forward, slots)
	assert(id, "CoverNode requires Id")
	assert(position, "CoverNode requires Position")
	assert(forward, "CoverNode requires Forward")

	local self = setmetatable({}, CoverNode)

	self.Id = id
	self.Position = position
	self.Forward = forward.Unit
	self.Slots = slots or 1
	self.Occupants = {}
	self.Reserved = {}
	self.DistanceList = {}
	self.DistanceMap = {}
	
	if DebugState then
		local part = Instance.new("Part")
		part.Size = Vector3.new(1,1,1)
		part.Anchored = true
		part.CanCollide = false
		part.Position = position + Vector3.new(0, 2, 0)
		part.Color = Color3.fromRGB(255,255,255)
		part.Parent = workspace

		self.DebugPart = part
		self.DebugScore = nil
		self:AttachScoreBillboard()
	end	

	return self
end

function CoverNode:GetDistanceFrom(pos)
	local a = Vector3.new(self.Position.X, 0, self.Position.Z)
	local b = Vector3.new(pos.X, 0, pos.Z)
	return (a - b).Magnitude
end

function CoverNode:AttachScoreBillboard()

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = self.DebugPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 0)
	label.Parent = billboard
	label.Text = ""

	self.DebugLabel = label
end

return CoverNode
