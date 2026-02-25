--[[
DemolitionistFireController.lua

Placeholder fire controller implementation.
Delegates to InfantryFireController until Demolitionist-specific firing logic is implemented.
]]

local InfantryFireController = require(script.Parent.InfantryFireController)

local DemolitionistFireController = setmetatable({}, { __index = InfantryFireController })

return DemolitionistFireController
