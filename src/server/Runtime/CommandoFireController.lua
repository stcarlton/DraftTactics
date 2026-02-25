--[[
CommandoFireController.lua

Placeholder fire controller implementation.
Delegates to InfantryFireController until Commando-specific firing logic is implemented.
]]

local InfantryFireController = require(script.Parent.InfantryFireController)

local CommandoFireController = setmetatable({}, { __index = InfantryFireController })

return CommandoFireController
