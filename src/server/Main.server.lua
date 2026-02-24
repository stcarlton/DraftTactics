--[[
Main.server.lua

Role:
- Entry point for server simulation.
- Initializes core services.
- Connects RunService to battle update loop.

Owns:
- Service boot order.
- Simulation tick binding.
- High-level phase progression.

Does NOT:
- Contain game logic.
- Execute per-unit behavior.
- Compute combat results.
- Build battlefield geometry.
- Make tactical decisions.

Invariants:
- Thin orchestration layer only.
- No business logic.
- Deterministic update order.
- Services are initialized once.

Collaborators:
- BattleService
- BattlefieldService
- GamePhase
- RunService
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BattlefieldService = require(script.Parent.Services.BattlefieldService)
local BattleService = require(script.Parent.Services.BattleService)
local CoverVisualizer = require(script.Parent.Debug.CoverVisualizer)

local TeamConfig = require(ReplicatedStorage.Shared.Configs.TeamConfig)
local GamePhase = require(ReplicatedStorage.Shared.Types.GamePhase)
local DeploymentTile = require(ReplicatedStorage.Shared.Deployment.DeploymentTile)
local FormationGrid = require(ReplicatedStorage.Shared.Deployment.FormationGrid)

--for testing
local TestDeployments = require(ReplicatedStorage.Shared.Deployment.TestDeployments)
local TestTeams = require(ReplicatedStorage.Shared.Deployment.TestTeams)

---------------------------------------------------------------------
-- Startup
---------------------------------------------------------------------

local STARTUP_DELAY = 1

local StateFolder = ReplicatedStorage:FindFirstChild("State") or Instance.new("Folder")
StateFolder.Name = "State"
StateFolder.Parent = ReplicatedStorage

local phaseValue = StateFolder:FindFirstChild("GamePhaseValue")
phaseValue.Name = "GamePhaseValue"
phaseValue.Parent = StateFolder

local function SetPhase(p)
	CurrentPhase = p
	phaseValue.Value = p
end

BattlefieldService:Build()

local TeamA = TeamConfig.new("A", "You", "Balanced")
local TeamB = TeamConfig.new("B", "Enemy_001", "Balanced")

TeamA.Formation = FormationGrid.new()

-- DEV / MODE SWITCH
local SKIP_PREBATTLE_UI = true

if SKIP_PREBATTLE_UI then
	TeamA.Tiles = TestDeployments.Stalk                          
else
	TeamA.Units = TestTeams.Balanced
end

TeamB.Tiles = TestDeployments.Stalk

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StartBattle = Remotes:WaitForChild("StartBattle")

if SKIP_PREBATTLE_UI then
	print("[DEV] Skipping PreBattle UI")

	BattleService.TeamA = TeamA
	BattleService.TeamB = TeamB

	SetPhase(GamePhase.Battle)
	Remotes.PhaseChanged:FireAllClients(GamePhase.Battle)

	BattleService:StartBattle()
else
	SetPhase(GamePhase.PreBattle)	
end

local tileIndex = 1

for _, unitEntry in ipairs(TeamA.Units) do
	for i = 1, unitEntry.Count do
		local tileId = unitEntry.Class .. tileIndex
		tileIndex += 1

		local tile = DeploymentTile.new(
			tileId,
			unitEntry.Class
		)

		table.insert(TeamA.Tiles, tile)
	end
end


local GetPreBattleState = Remotes:WaitForChild("GetPreBattleState")
local PlaceTile = Remotes:WaitForChild("PlaceTile")

local function findTile(team, tileId)
	for _, tile in ipairs(team.Tiles) do
		if tile.TileId == tileId then
			return tile
		end
	end
	return nil
end


PlaceTile.OnServerInvoke = function(player, tileId, row, col)
	local team = TeamA
	local tile = findTile(team, tileId)
	local formation = team.Formation

	local success, err = formation:PlaceTile(tileId, row, col)
	if not success then
		return false, err
	end

	tile.Deployed = true
	tile.Row = row
	tile.Col = col

	return true, {
		TeamA = team,
	}
end

---------------------------------------------------------------------
-- Lighting (authoritative, deterministic)
---------------------------------------------------------------------

local Lighting = game:GetService("Lighting")

Lighting.GlobalShadows = false

Lighting.Brightness = 1
Lighting.ClockTime = 16

Lighting.Ambient = Color3.fromRGB(40, 40, 40)
Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 50)

for _, child in ipairs(Lighting:GetChildren()) do
	if child:IsA("Atmosphere")
		or child:IsA("BloomEffect")
		or child:IsA("ColorCorrectionEffect")
	then
		child:Destroy()
	end
end



GetPreBattleState.OnServerInvoke = function(player)
	print("GetPreBattleState invoked by client")
	return {
		TeamA = TeamA,
	}
end

StartBattle.OnServerEvent:Connect(function(player)
	print("[FLOW] StartBattle requested by", player.Name)
	BattleService.TeamA = TeamA
	BattleService.TeamB = TeamB

	Remotes.PhaseChanged:FireAllClients(GamePhase.Battle)
	SetPhase(GamePhase.Battle)

	BattleService:StartBattle()
end)


task.wait(STARTUP_DELAY)
CoverVisualizer:Draw()

RunService.Heartbeat:Connect(function(dt)
	if CurrentPhase ~= GamePhase.Battle then
		return
	end

	for _, unit in ipairs(BattleService.Units) do
		unit:UpdatePerception(BattleService.Units)
	end

	for _, unit in ipairs(BattleService.Units) do
		unit:Update(dt)
	end
	
	if BattleService:IsBattleOver() then
		print("Battle over")
	end
end)

