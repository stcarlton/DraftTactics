-- Shared/Types/BattleState.lua

local BattleState = table.freeze({
	Idle     = "Idle",
	Spawning = "Spawning",
	Running  = "Running",
	Ended    = "Ended",
})

return BattleState
