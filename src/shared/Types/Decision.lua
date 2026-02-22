-- Decision.lua

local Decision = table.freeze({
	None   = "None",
	Melee   = "Melee",
	Charge = "Charge",
	Hold = "Hold",
	SeekObjective = "SeekObjective",
	SeekEnemy = "SeekEnemy",
	SeekAcross = "SeekAcross",
	Destroy = "Destroy",
	Reposition = "Reposition",
	Engage = "Engage",
	Plan = "Plan",
	TakeCover = "TakeCover",
	TakeTower = "TakeTower",
	DefendObjective = "DefendObjective",
})


return Decision
