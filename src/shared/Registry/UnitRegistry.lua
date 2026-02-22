--UnitRegistry.lua

local InfantryBrain = require(game.ServerScriptService.Server.Runtime.InfantryBrain)
local SniperBrain = require(game.ServerScriptService.Server.Runtime.SniperBrain)

local UnitConfigs = require(game.ReplicatedStorage.Shared.Configs.UnitConfigs)
local Class = require(game.ReplicatedStorage.Shared.Types.Class)

local UnitRegistry = {

	[Class.Infantry] = {
		Config = UnitConfigs.Infantry,
		Brain  = InfantryBrain,
		ModelName = "InfantryModel",
	},

	[Class.Sniper] = {
		Config = UnitConfigs.Sniper,
		Brain  = SniperBrain,
		ModelName = "SniperModel",
	},

}

return UnitRegistry
