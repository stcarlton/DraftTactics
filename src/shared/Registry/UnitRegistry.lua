-- UnitRegistry.lua
-- Maps unit Class → Config, Brain, and Model.

local InfantryBrain = require(game.ServerScriptService.Server.Runtime.InfantryBrain)
local SniperBrain = require(game.ServerScriptService.Server.Runtime.SniperBrain)
local CommandoBrain = require(game.ServerScriptService.Server.Runtime.CommandoBrain)
local DemolitionistBrain = require(game.ServerScriptService.Server.Runtime.DemolitionistBrain)
local InfantryFireController = require(game.ServerScriptService.Server.Runtime.InfantryFireController)
local SniperFireController = require(game.ServerScriptService.Server.Runtime.SniperFireController)
local CommandoFireController = require(game.ServerScriptService.Server.Runtime.CommandoFireController)
local DemolitionistFireController = require(game.ServerScriptService.Server.Runtime.DemolitionistFireController)
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

	[Class.Commando] = {
		Config = UnitConfigs.Commando,
		Brain  = CommandoBrain,
		FireController = CommandoFireController,
		AnimationController = AnimationController,
		ModelName = "CommandoModel",
	},

	[Class.Demolitionist] = {
		Config = UnitConfigs.Demolitionist,
		Brain  = DemolitionistBrain,
		FireController = DemolitionistFireController,
		AnimationController = AnimationController,
		ModelName = "DemolitionistModel",
	},

}

return UnitRegistry
