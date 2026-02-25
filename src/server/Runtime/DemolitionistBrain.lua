--[[
DemolitionistBrain.lua

Placeholder brain implementation.
Delegates to InfantryBrain until Demolitionist-specific behavior is implemented.
]]

local InfantryBrain = require(script.Parent.InfantryBrain)

local DemolitionistBrain = setmetatable({}, { __index = InfantryBrain })

return DemolitionistBrain
