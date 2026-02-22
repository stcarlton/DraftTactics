--ObjectiveConfigs.lua

local ObjectiveConfigs = {}

ObjectiveConfigs.MainObjective = {
	Id = "MainObjective",
	ModelName = "ObjectiveModel",
	MaxHealth = 15000,
	CoverReduction = 0,
	DamageReduction = 0,

	GridArea = {
		A = { RowStart =5, RowEnd = 6, ColStart = 3, ColEnd = 4, rowT = 0.75, colT = 0.5 }, -- friendly
		B = { RowStart = 1, RowEnd = 2, ColStart = 3, ColEnd = 4, rowT = 0.25, colT = 0.5 }, -- enemy
	},
	
	Height = 3,

	Facing = {
		A = Vector3.new(0, 0, -1),
		B = Vector3.new(0, 0,  1),
	},
}

return ObjectiveConfigs
