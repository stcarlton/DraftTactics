-- TeamConfig.lua
-- Logical representation of a team before battle

local TeamConfig = {}

function TeamConfig.new(id, username, identity)
	return {
		Id = id,
		Username = username,
		Identity = identity,
		Units = {},
		Tiles = {},
		Deployment = {},
		Formation = nil,
	}
end

return TeamConfig
