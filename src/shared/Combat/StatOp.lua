-- StatOp.lua
-- Enum of stat operation types (Add, Mul, Set, etc).

local StatOp = table.freeze({
	Add     = "Add",
	Mul     = "Mul",
	Perc    = "Perc",
	Set     = "Set",
})

return StatOp
