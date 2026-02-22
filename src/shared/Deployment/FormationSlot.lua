-- FormationSlot.lua

local FormationSlot = {}
FormationSlot.__index = FormationSlot

function FormationSlot.new(row, col)
	return setmetatable({
		Row = row,
		Col = col,
		TileId = nil,
	}, FormationSlot)
end

function FormationSlot:IsEmpty()
	return self.TileId == nil
end

return FormationSlot
