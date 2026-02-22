-- TowerConfigs.lua
-- Static definition of tower interaction zones

local TowerConfigs = {
	Default = {
		LadderOffset = Vector3.new(0, 0, 7),
		TopOffset    = Vector3.new(0, 11, 4),

		ClimbStartY  = 2.5,

		SlotOffsets = {
			[1] = Vector3.new(-1.5, 0, -7),
			[2] = Vector3.new( 1.5, 0, -7),
		},
	}
}

return TowerConfigs
