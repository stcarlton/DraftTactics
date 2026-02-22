-- SpawnPlanBuilder.lua

local SpawnPlanBuilder = {}

local StrategyUtil =require(game.ReplicatedStorage.Shared.Types.Strategy)
local GridUtil = require(game.ReplicatedStorage.Shared.Util.GridUtil)
local DraftDefinitions = require(game.ReplicatedStorage.Shared.Configs.DraftDefinitions)

local COL_WIDTH = GridUtil.MAP_SIZE / 6

local function colToLateralOffset(col)
	return (col - 3.5) * COL_WIDTH
end

function SpawnPlanBuilder.Build(teams)
	local plan = {}

	for teamId, team in pairs(teams) do
		for _, tile in ipairs(team.Tiles) do
			assert(tile.Deployed, "SpawnPlanBuilder: undeployed tile found")
			assert(tile.Row and tile.Col, "SpawnPlanBuilder: tile missing row/col")

			local strategy = StrategyUtil.GetStrategyForRow(tile.Row)
			local t = tile.Row % 2
			local def = DraftDefinitions[tile.Class]


			for i = 1, def.SpawnCount do
				local spawnTime = t + math.random()
				local lateral = colToLateralOffset(tile.Col) + (i - def.SpawnCount + 1) * (COL_WIDTH / def.SpawnCount)
				table.insert(plan, {
					TeamId = teamId,
					Class = tile.Class,
					Strategy = strategy,
					SpawnDelay = spawnTime,
					LateralOffset = lateral,
					TileId = tile.TileId,
					Row = tile.Row,
					Col = tile.Col,
					SpawnIndex = i,
				})
			end
		end
	end

	return plan
end

return SpawnPlanBuilder
