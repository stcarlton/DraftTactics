-- UnitRegistry.lua
-- Maps unit Class → Config, Brain, and Model.

local InfantryBrain = require(game.ServerScriptService.Server.Runtime.InfantryBrain)
local SniperBrain = require(game.ServerScriptService.Server.Runtime.SniperBrain)
local InfantryFireController = require(game.ServerScriptService.Server.Runtime.InfantryFireController)
local SniperFireController = require(game.ServerScriptService.Server.Runtime.SniperFireController)
local AnimationController = require(game.ServerScriptService.Server.Runtime.AnimationController)

local UnitConfigs = require(game.ReplicatedStorage.Shared.Configs.UnitConfigs)
local Class = require(game.ReplicatedStorage.Shared.Types.Class)

local UnitRegistry = {

	[Class.Infantry] = {
		Config = UnitConfigs.Infantry,
		Brain  = InfantryBrain,
		FireController = InfantryFireController,
		AnimationController = AnimationController,
		ModelName = "InfantryModel",
	},

	[Class.Sniper] = {
		Config = UnitConfigs.Sniper,
		Brain  = SniperBrain,
		FireController = SniperFireController,
		AnimationController = AnimationController,
		ModelName = "SniperModel",
	},

}

return UnitRegistry
