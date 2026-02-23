-- TestTeams.lua
-- Static test team roster definitions for development.

local Class = require(game.ReplicatedStorage.Shared.Types.Class)

local TestTeams = {}

TestTeams.Balanced = {
	{ Class = Class.Infantry, Count = 6 },
	{ Class = Class.Sniper, Count = 3 },
}

return TestTeams