-- GridUtil.lua

local GridUtil = {}

GridUtil.MAP_SIZE = 400
GridUtil.GRID_SIZE = 6

local CELL_SIZE = GridUtil.MAP_SIZE / GridUtil.GRID_SIZE
local HALF = GridUtil.MAP_SIZE / 2

local function CellCenter(row, col)
	local x = -HALF + CELL_SIZE * (col - 0.5)
	local z = -HALF + CELL_SIZE * (row - 0.5)
	return Vector3.new(x, 0, z)
end

function GridUtil.AreaCenter(rowStart, rowEnd, colStart, colEnd, height, rowT, colT)
	assert(rowStart <= rowEnd, "rowStart must be <= rowEnd")
	assert(colStart <= colEnd, "colStart must be <= colEnd")

	rowT = rowT or 0.5
	colT = colT or 0.5

	local startCell = CellCenter(rowStart, colStart)
	local endCell   = CellCenter(rowEnd, colEnd)

	local z = startCell.Z + (endCell.Z - startCell.Z) * rowT
	local x = startCell.X + (endCell.X - startCell.X) * colT

	return Vector3.new(x, height or 0, z)
end

function GridUtil.GetBoundsOfArea(rowMin, rowMax, colMin, colMax, height)
	assert(rowMin <= rowMax, "rowMin must be <= rowMax")
	assert(colMin <= colMax, "colMin must be <= colMax")

	local centerMin = GridUtil.AreaCenter(rowMin, rowMin, colMin, colMin, height)
	local centerMax = GridUtil.AreaCenter(rowMax, rowMax, colMax, colMax, height)

	local halfCell = CELL_SIZE / 2

	local minPos = Vector3.new(
		centerMin.X - halfCell,
		height or 0,
		centerMin.Z - halfCell
	)

	local maxPos = Vector3.new(
		centerMax.X + halfCell,
		height or 0,
		centerMax.Z + halfCell
	)

	return minPos, maxPos
end

return GridUtil