-- DeploymentTile.lua
-- Data container for a single pre-battle deployment tile.

local DeploymentTile = {}
DeploymentTile.__index = DeploymentTile

function DeploymentTile.new(tileId, class)
	return setmetatable({
		TileId = tileId,
		Class = class,
		Deployed = false,
		Row = nil,
		Col = nil,
	}, DeploymentTile)
end

return DeploymentTile
