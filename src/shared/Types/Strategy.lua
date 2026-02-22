-- Strategy.lua

local Strategy = {
	Blitz = "Blitz",
	Stalk = "Stalk",
	Defend = "Defend",
}

local function GetStrategyForRow(row)
	if row <= 2 then
		return Strategy.Blitz
	elseif row <= 4 then
		return Strategy.Stalk
	else
		return Strategy.Defend
	end
end

return {
	GetStrategyForRow = GetStrategyForRow,
	Strategy = Strategy,
}
