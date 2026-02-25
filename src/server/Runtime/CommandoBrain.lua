--[[
CommandoBrain.lua

Placeholder brain implementation.
Delegates to InfantryBrain until Commando-specific behavior is implemented.
]]

local InfantryBrain = require(script.Parent.InfantryBrain)

local CommandoBrain = setmetatable({}, { __index = InfantryBrain })

return CommandoBrain
