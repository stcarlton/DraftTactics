--[[
PreBattleUI.client.lua

Role:
- Client-side deployment UI.
- Handles tile drag/drop.
- Renders 6×6 formation grid.

Owns:
- Visual grid state.
- Ghost tile rendering.
- Input handling for placement.
- Server sync requests.

Does NOT:
- Spawn units.
- Validate final authority state.
- Decide battle logic.
- Persist game state.

Invariants:
- Server is authoritative.
- UI always re-renders from server truth.
- No accumulated event connections.
- Grid remains world-aligned and centered.

Collaborators:
- FormationGrid (data snapshot)
- GamePhase (phase switching)
- Server deployment endpoint
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local GamePhaseValue = ReplicatedStorage:WaitForChild("State"):WaitForChild("GamePhaseValue")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[UI] PreBattleUI started")

for _, guiType in ipairs({
	Enum.CoreGuiType.Chat,
	Enum.CoreGuiType.PlayerList,
	Enum.CoreGuiType.Backpack,
	}) do
	pcall(function()
		StarterGui:SetCoreGuiEnabled(guiType, false)
	end)
end

local GRID_SIZE = 6
local GRID_BG_TRANSPARENCY = 0.95
local CELL_BG_TRANSPARENCY = 0.82
local CELL_BORDER_COLOR   = Color3.fromRGB(110,110,110)
local CELL_BORDER_THICK   = 1
local SLOT_BG_ALPHA       = 0.20
local SLOT_BG_FULL_ALPHA  = 0.20
local SLOT_BORDER_COLOR   = Color3.fromRGB(140,140,140)
local SLOT_BORDER_HOVER   = Color3.fromRGB(120,200,255)
local STANCE_BLOCK_ALPHA  = 0.15
local STANCE_TEXT_COLOR  = Color3.new(1,1,1)
local STANCE_DESC_COLOR  = Color3.fromRGB(220,220,220)

local STANCE_COLORS = {
	Blitz  = Color3.fromRGB(120,60,40),
	Stalk  = Color3.fromRGB(40,80,120),
	Defend = Color3.fromRGB(70,70,80),
}

local ROW_TINTS = {
	STANCE_COLORS.Blitz,
	STANCE_COLORS.Blitz,
	STANCE_COLORS.Stalk,
	STANCE_COLORS.Stalk,
	STANCE_COLORS.Defend,
	STANCE_COLORS.Defend,
}

local STANCE_OUTLINE_THICKNESS = 6
local STANCE_OUTLINE_ALPHA = 0

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetPreBattleState = Remotes:WaitForChild("GetPreBattleState")
local PlaceTile = Remotes:WaitForChild("PlaceTile")

local state = GetPreBattleState:InvokeServer()
local friendly = state.TeamA

local tileById = {}

local function rebuildTileLookup()
	tileById = {}
	for _, t in ipairs(friendly.Tiles) do
		tileById[t.TileId] = t
	end
end

rebuildTileLookup()

local gui = Instance.new("ScreenGui")
gui.Name = "PreBattleUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1,1)
root.BackgroundTransparency = 1
root.Parent = gui

local draggingTileId = nil
local dragGhost = nil
local hoveredSlot = nil

local startButton = Instance.new("TextButton")
startButton.Name = "StartBattleButton"
startButton.Size = UDim2.fromOffset(180, 48)
startButton.Position = UDim2.fromScale(1, 1)
startButton.AnchorPoint = Vector2.new(1, 1)
startButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
startButton.BorderSizePixel = 0
startButton.Text = "START BATTLE"
startButton.Font = Enum.Font.GothamBold
startButton.TextSize = 16
startButton.TextColor3 = Color3.new(1, 1, 1)
startButton.Parent = root
startButton.Position = UDim2.new(1, -24, 1, -24)


local StartBattle = Remotes:WaitForChild("StartBattle")

startButton.MouseButton1Click:Connect(function()
	print("[UI] Start Battle clicked")
	StartBattle:FireServer()
end)

local staging = Instance.new("Frame")
staging.Name = "StagingPanel"
staging.Size = UDim2.fromScale(0.22, 0.7)
staging.Position = UDim2.fromScale(0.03, 0.15)
staging.BackgroundTransparency = 1
staging.Parent = root

local stagingLayout = Instance.new("UIGridLayout")
stagingLayout.CellSize = UDim2.fromOffset(80,80)
stagingLayout.CellPadding = UDim2.fromOffset(10,10)
stagingLayout.Parent = staging

local gridWrapper = Instance.new("Frame")
gridWrapper.Name = "GridWrapper"
gridWrapper.Size = UDim2.fromScale(0.55, 0.8)
gridWrapper.AnchorPoint = Vector2.new(0.5, 0)
gridWrapper.Position = UDim2.fromScale(0.5, 0.1)
gridWrapper.BackgroundTransparency = 1
gridWrapper.Parent = root

local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 1
aspect.DominantAxis = Enum.DominantAxis.Height
aspect.Parent = gridWrapper

local gridFrame = Instance.new("Frame")
gridFrame.Name = "GridFrame"
gridFrame.Size = UDim2.fromScale(1,1)
gridFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
gridFrame.BackgroundTransparency = GRID_BG_TRANSPARENCY
gridFrame.BorderSizePixel = 0
gridFrame.Parent = gridWrapper

local stancePanel = Instance.new("Frame")
stancePanel.Name = "StancePanel"
stancePanel.Size = UDim2.fromScale(0.20, 0.8)
stancePanel.AnchorPoint = Vector2.new(0, 0)
stancePanel.BackgroundTransparency = 1
stancePanel.BorderSizePixel = 0
stancePanel.Parent = root

local STANCE_Y_OFFSET_PX = 58

local function syncStancePanel()
	local pos = gridWrapper.AbsolutePosition
	local size = gridWrapper.AbsoluteSize

	stancePanel.Position = UDim2.fromOffset(
		pos.X + size.X,
		pos.Y + STANCE_Y_OFFSET_PX
	)

	stancePanel.Size = UDim2.fromOffset(
		size.X * 0.40,
		size.Y
	)
end

local function addStanceBlock(title, desc, color, index)
	local block = Instance.new("Frame")
	block.Size = UDim2.new(1, 0, 2 / GRID_SIZE, 0)
	block.Position = UDim2.new(0, 0, (index * 2) / GRID_SIZE, 0)
	block.BackgroundColor3 = color
	block.BackgroundTransparency = STANCE_BLOCK_ALPHA
	block.BorderSizePixel = 0
	block.Parent = stancePanel
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = block
	
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0,12)
	pad.PaddingBottom = UDim.new(0,12)
	pad.PaddingLeft = UDim.new(0,12)
	pad.PaddingRight = UDim.new(0,12)
	pad.Parent = block

	local header = Instance.new("TextLabel")
	header.Text = title
	header.Font = Enum.Font.GothamBold
	header.TextSize = 32
	header.TextColor3 = STANCE_TEXT_COLOR
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1,0)
	header.AutomaticSize = Enum.AutomaticSize.Y
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = block

	local body = Instance.new("TextLabel")
	body.Text = desc
	body.Font = Enum.Font.Gotham
	body.TextSize = 18
	body.TextWrapped = true
	body.TextColor3 = STANCE_DESC_COLOR
	body.BackgroundTransparency = 1
	body.Size = UDim2.fromScale(1,0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Parent = block
	
	header.LayoutOrder = 1
	body.LayoutOrder = 2
end

addStanceBlock(
	"BLITZ",
	"Destory the enemy objective.\nNothing else matters.\n\n+20% movement speed\nCharge",
	STANCE_COLORS.Blitz,
	0
)

addStanceBlock(
	"STALK",
	"Hunt the enemy from the shadows.\nOrchestrate the perfect ambush.\n\n+5% Damage bonus\nStealth",
	STANCE_COLORS.Stalk,
	1
)

addStanceBlock(
	"DEFEND",
	"Break the enemy against your walls.\n\n+5% Damage Reduction\nTower",
	STANCE_COLORS.Defend,
	2
)

local gridSlots = {}

local function buildGrid()
	gridFrame:ClearAllChildren()
	gridSlots = {}

	local total = gridFrame.AbsoluteSize.X
	local cellSize = math.floor(total / GRID_SIZE)

	for r = 1, GRID_SIZE do
		gridSlots[r] = {}

		for c = 1, GRID_SIZE do
			local cell = Instance.new("Frame")
			cell.Size = UDim2.fromOffset(cellSize, cellSize)
			cell.Position = UDim2.fromOffset((c-1)*cellSize, (r-1)*cellSize)
			cell.BackgroundColor3 = ROW_TINTS[r]
			cell.BackgroundTransparency = CELL_BG_TRANSPARENCY
			cell.BorderSizePixel = CELL_BORDER_THICK
			cell.BorderColor3 = CELL_BORDER_COLOR
			cell.Parent = gridFrame

			local slot = Instance.new("Frame")
			slot.Size = UDim2.new(1,-12,1,-12)
			slot.Position = UDim2.fromOffset(6,6)
			slot.BackgroundTransparency = 1
			slot.BorderSizePixel = 0
			slot.Active = true
			slot.Parent = cell

			local inner = Instance.new("Frame")
			inner.Size = UDim2.fromScale(1,1)
			inner.BackgroundTransparency = 1
			inner.BorderSizePixel = 1
			inner.BorderColor3 = SLOT_BORDER_COLOR
			inner.Parent = slot

			slot.MouseEnter:Connect(function()
				if draggingTileId then
					hoveredSlot = { row = r, col = c }
					inner.BorderColor3 = SLOT_BORDER_HOVER
				end
			end)

			slot.MouseLeave:Connect(function()
				if hoveredSlot and hoveredSlot.row == r and hoveredSlot.col == c then
					hoveredSlot = nil
				end
				inner.BorderColor3 = SLOT_BORDER_COLOR
			end)

			slot.InputEnded:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				if not draggingTileId then return end

				local ok, result = PlaceTile:InvokeServer(draggingTileId, r, c)
				if ok then
					friendly = result.TeamA
					rebuildTileLookup()
				end

				if dragGhost then
					dragGhost:Destroy()
					dragGhost = nil
				end

				draggingTileId = nil
				renderTiles()
			end)

			gridSlots[r][c] = slot
		end
	end
end

local function createTileFrame(tile, size, parent, transparency)
	local frame = Instance.new("Frame")
	frame.Name = "TileFrame"
	frame.Size = size
	frame.BackgroundColor3 = Color3.fromRGB(90,90,90)
	frame.BackgroundTransparency = transparency
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.fromRGB(200,200,200)
	frame.Active = true
	frame.ZIndex = 10
	frame.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1,1,1)
	label.Font = Enum.Font.Gotham
	label.TextWrapped = true
	label.Text = tile.Class
	label.TextSize = size == UDim2.fromOffset(80,80) and 14 or 12
	label.Parent = frame

	frame.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		draggingTileId = tile.TileId
		renderTiles()

		dragGhost = createTileFrame(tile, UDim2.fromOffset(80,80), root, 0.2)
		dragGhost.Position = UDim2.fromOffset(
			input.Position.X - dragGhost.Size.X.Offset/2,
			input.Position.Y
		)
		dragGhost.ZIndex = 100
	end)

	return frame
end

function renderTiles()
	for _, child in ipairs(staging:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for r=1,GRID_SIZE do
		for c=1,GRID_SIZE do
			local slot = gridSlots[r][c]
			local tile = slot:FindFirstChild("TileFrame")
			if tile then tile:Destroy() end
		end
	end

	for _, tile in ipairs(friendly.Tiles) do
		if tile.TileId ~= draggingTileId then
			if not tile.Deployed then
				createTileFrame(tile, UDim2.fromOffset(80,80), staging, SLOT_BG_ALPHA)
			else
				createTileFrame(
					tile,
					UDim2.fromScale(1,1),
					gridSlots[tile.Row][tile.Col],
					SLOT_BG_FULL_ALPHA
				)
			end
		end
	end
end

UserInputService.InputChanged:Connect(function(input)
	if draggingTileId and dragGhost and input.UserInputType == Enum.UserInputType.MouseMovement then
		dragGhost.Position = UDim2.fromOffset(
			input.Position.X - dragGhost.Size.X.Offset/2,
			input.Position.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if not draggingTileId then return end

	if hoveredSlot then
		local ok, result = PlaceTile:InvokeServer(
			draggingTileId,
			hoveredSlot.row,
			hoveredSlot.col
		)

		if ok then
			friendly = result.TeamA
			rebuildTileLookup()
		end
	end

	if dragGhost then
		dragGhost:Destroy()
		dragGhost = nil
	end

	draggingTileId = nil
	hoveredSlot = nil
	renderTiles()
end)

local function createStanceOutlineRow(parent, yOffset, height, color)
	local row = Instance.new("Frame")
	row.Name = "StanceOutlineRow"
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.ZIndex = 40

	-- Anchor to RIGHT, extend LEFT
	row.AnchorPoint = Vector2.new(1, 0)
	row.Position = UDim2.fromOffset(0, yOffset)
	row.Size = UDim2.fromOffset(1, height)
	row.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = STANCE_OUTLINE_THICKNESS
	stroke.Transparency = STANCE_OUTLINE_ALPHA
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = row

	return row
end

local stanceOutlineRows = {
	Blitz  = createStanceOutlineRow(stancePanel, 0, 0, STANCE_COLORS.Blitz),
	Stalk  = createStanceOutlineRow(stancePanel, 0, 0, STANCE_COLORS.Stalk),
	Defend = createStanceOutlineRow(stancePanel, 0, 0, STANCE_COLORS.Defend),
}

local OUTLINE_WIDTH_OFFSET_X = 5

local function layoutStanceOutlines()
	local gridHeight = gridFrame.AbsoluteSize.Y
	local rowHeight = gridHeight / GRID_SIZE

	local gridWidth = gridFrame.AbsoluteSize.X
	local panelWidth = stancePanel.AbsoluteSize.X
	local totalWidth = gridWidth + panelWidth

	local gridTop = gridFrame.AbsolutePosition.Y
	local panelTop = stancePanel.AbsolutePosition.Y
	local yOffset = gridTop - panelTop
	
	local t = STANCE_OUTLINE_THICKNESS
	
	stanceOutlineRows.Blitz.Position =
		UDim2.fromOffset(
			panelWidth - t,
			yOffset + t
		)

	stanceOutlineRows.Blitz.Size =
		UDim2.fromOffset(
			totalWidth - t * 2 + OUTLINE_WIDTH_OFFSET_X,
			rowHeight * 2 - t * 2
		)

	stanceOutlineRows.Stalk.Position =
		UDim2.fromOffset(
			panelWidth - t,
			yOffset + rowHeight * 2 + t
		)

	stanceOutlineRows.Stalk.Size =
		UDim2.fromOffset(
			totalWidth - t * 2 + OUTLINE_WIDTH_OFFSET_X,
			rowHeight * 2 - t * 2
		)

	stanceOutlineRows.Defend.Position =
		UDim2.fromOffset(
			panelWidth - t,
			yOffset + rowHeight * 4 + t
		)

	stanceOutlineRows.Defend.Size =
		UDim2.fromOffset(
			totalWidth - t * 2 + OUTLINE_WIDTH_OFFSET_X,
			rowHeight * 2 - t * 2
		)

end

print("[UI] PreBattleUI ready")

local PhaseChanged = Remotes:WaitForChild("PhaseChanged")

PhaseChanged.OnClientEvent:Connect(function(phase)
	if phase ~= "Battle" then return end

	print("[UI] Entering Battle Phase")

	gui:Destroy()
end)

if GamePhaseValue.Value == "Battle" then
	print("[UI] Battle already in progress; skipping PreBattle UI")
	gui:Destroy()
	return
end

buildGrid()
renderTiles()
syncStancePanel()
task.defer(layoutStanceOutlines)


local function onGridLayoutChanged()
	buildGrid()
	renderTiles()
	syncStancePanel()
	task.defer(layoutStanceOutlines)
end

gridWrapper:GetPropertyChangedSignal("AbsolutePosition"):Connect(onGridLayoutChanged)
gridWrapper:GetPropertyChangedSignal("AbsoluteSize"):Connect(onGridLayoutChanged)


print("[UI] PreBattleUI ready")
