-- Helpers.lua
-- General math and utility helper functions.

local Helpers = {}

function Helpers.IsFacing(positionA, forwardA, positionB, threshold)
	threshold = threshold or 0
	local toTarget = (positionB - positionA).Unit
	return forwardA:Dot(toTarget) >= threshold
end

return Helpers