--[[
FormationGrid.lua

Role:
- Container for 6×6 deployment grid.
- Stores tile placement state.

Owns:
- Grid slots.
- Tile insertion/removal.
- Snapshot generation.

Does NOT:
- Spawn units.
- Validate battle rules.
- Execute gameplay logic.

Rules:
- No side effects outside grid state.
- Deterministic snapshot output.

Used By:
- PreBattleUI
- SpawnPlanBuilder
]]

local FormationSlot = require(script.Parent.FormationSlot)
local GridUtil = require(script.Parent.Parent.Util.GridUtil)

local FormationGrid = {}
FormationGrid.__index = FormationGrid

local ROWS = GridUtil.GRID_SIZE
local COLS = GridUtil.GRID_SIZE

function FormationGrid.new()
	local self = setmetatable({}, FormationGrid)

	self.Rows = ROWS
	self.Cols = COLS
	self.Slots = {}

	for r = 1, ROWS do
		self.Slots[r] = {}
		for c = 1, COLS do
			self.Slots[r][c] = FormationSlot.new(r, c)
		end
	end

	return self
end

function FormationGrid:GetSlot(row, col)
	if self.Slots[row] then
		return self.Slots[row][col]
	end
	return nil
end

function FormationGrid:ClearTile(tileId)
	for r = 1, self.Rows do
		for c = 1, self.Cols do
			local slot = self.Slots[r][c]
			if slot.TileId == tileId then
				slot.TileId = nil
				return
			end
		end
	end
end

function FormationGrid:PlaceTile(tileId, row, col)
	local slot = self:GetSlot(row, col)
	if not slot then
		return false, "Invalid slot"
	end

	if not slot:IsEmpty() then
		return false, "Slot occupied"
	end

	-- Remove from previous location
	self:ClearTile(tileId)

	slot.TileId = tileId
	return true
end

return FormationGrid
