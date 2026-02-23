-- DraftDefinitions.lua
-- Defines unit spawn counts and draft-related configuration.

local Class = require(game.ReplicatedStorage.Shared.Types.Class)

local DraftDefinitions = {}

DraftDefinitions = {
	[Class.Infantry] = {
		SpawnCount = 3,
	},
	[Class.Sniper] = {
		SpawnCount = 1,
	},
	[Class.Commando] = {
		SpawnCount = 1,
	},
	[Class.Demolitionist] = {
		SpawnCount = 1,
	},
}


return DraftDefinitions
