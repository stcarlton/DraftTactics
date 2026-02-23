-- TestDeployments.lua
-- Static deployment layouts for development and testing.

local Class = require(game.ReplicatedStorage.Shared.Types.Class)
local DeploymentTile = require(game.ReplicatedStorage.Shared.Deployment.DeploymentTile)

local TestDeployments = {}

local function Tile(id, class, row, col)
	local tile = DeploymentTile.new(id, class)
	tile.Deployed = true
	tile.Row = row
	tile.Col = col
	return tile
end

TestDeployments.Blitz = {
	Tile("inf_1", Class.Infantry, 1, 1),
	Tile("inf_2", Class.Infantry, 1, 2),
	Tile("inf_3", Class.Infantry, 1, 3),
	Tile("inf_4", Class.Infantry, 1, 4),
	Tile("inf_5", Class.Infantry, 1, 5),
	Tile("inf_6", Class.Infantry, 1, 6),
	Tile("snip_1", Class.Sniper, 2, 1),
	Tile("snip_2", Class.Sniper, 2, 3),
	Tile("snip_3", Class.Sniper, 2, 5),
}

TestDeployments.Stalk = {
	Tile("inf_1", Class.Infantry, 3, 1),
	Tile("inf_2", Class.Infantry, 3, 2),
	Tile("inf_3", Class.Infantry, 3, 3),
	Tile("inf_4", Class.Infantry, 3, 4),
	Tile("inf_5", Class.Infantry, 3, 5),
	Tile("inf_6", Class.Infantry, 3, 6),
	Tile("snip_1", Class.Sniper, 4, 1),
	Tile("snip_2", Class.Sniper, 4, 3),
	Tile("snip_3", Class.Sniper, 4, 5),
}

TestDeployments.Defend = {
	Tile("inf_1", Class.Infantry, 5, 1),
	Tile("inf_2", Class.Infantry, 5, 2),
	Tile("inf_3", Class.Infantry, 5, 3),
	Tile("inf_4", Class.Infantry, 5, 4),
	Tile("inf_5", Class.Infantry, 5, 5),
	Tile("inf_6", Class.Infantry, 5, 6),
	Tile("snip_1", Class.Sniper, 6, 1),
	Tile("snip_2", Class.Sniper, 6, 3),
	Tile("snip_3", Class.Sniper, 6, 5),
}

TestDeployments.OneStalk = {
	Tile("test", Class.Infantry, 3, 3),
}

TestDeployments.OneSniper = {
	Tile("test", Class.Sniper, 3, 3),
}

TestDeployments.Balanced = {
	Tile("inf_1", Class.Infantry, 2, 2),
	Tile("sniper_1", Class.Sniper, 2, 4),
	--Tile("demo_1", Class.Demolitionist, 3, 3),
}

TestDeployments.Empty = {}


return TestDeployments
