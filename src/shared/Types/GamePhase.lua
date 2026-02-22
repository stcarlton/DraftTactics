-- GamePhase.lua
-- High-level lifecycle phases of a match

local GamePhase = table.freeze({
	PreBattle = "PreBattle",
	Battle    = "Battle",
	PostBattle = "PostBattle",
})

return GamePhase
