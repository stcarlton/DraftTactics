-- BattlefieldLayout.lua
--
-- Authoritative battlefield layout definition (MVP).
--
-- RESPONSIBILITIES:
--   • Define fixed tower positions per team
--   • Define tower semantics (slots, climb positions)
--   • Provide deterministic structure for defensive deployment
--
-- NON-RESPONSIBILITIES:
--   • Spawning models
--   • Cover logic
--   • AI decisions
--   • Movement or animation
--   • Randomness
--
-- DESIGN INVARIANT:
--   Towers are NOT cover.
--   They are sealed defensive emplacements entered by deployment,
--   not discovered or evaluated by AI.

local GridUtil = require(game.ReplicatedStorage.Shared.Util.GridUtil)

local BattlefieldLayout = {}

local TOWER_BASE_Y = 3
local TOWER_TOP_Y  = 18
local TOWER_SLOTS = 2

local function isEnemy(teamId)
	return teamId == "B"
end

local function backRow(teamId)
	return isEnemy(teamId) and 1 or GridUtil.GRID_SIZE
end

local function forwardDir(teamId)
	return isEnemy(teamId)
		and Vector3.new(0, 0, 1)
		or  Vector3.new(0, 0, -1)
end

local TOWER_COLUMNS = {
	{ 1, 2 },
	{ 3, 4 },
	{ 5, 6 },
}

function BattlefieldLayout.Build(teamId)
	assert(teamId == "A" or teamId == "B", "Invalid teamId")

	local layout = {
		Towers = {},
	}

	local row    = backRow(teamId)
	local facing = forwardDir(teamId)

	for index, cols in ipairs(TOWER_COLUMNS) do
		local center = GridUtil.AreaCenter(
			row, row,
			cols[1], cols[2]
		)

		local id = string.format("Tower_%s_%d", teamId, index)

		local tower = {
			Id = id,
			Team = teamId,
			BasePosition = Vector3.new(center.X, TOWER_BASE_Y, center.Z),
			TopPosition  = Vector3.new(center.X, TOWER_TOP_Y,  center.Z),
			Facing = facing,
			MaxSlots = TOWER_SLOTS,
			Occupants = {},
			Type = "Tower",
		}

		table.insert(layout.Towers, tower)
	end

	return layout
end

return BattlefieldLayout
