--[[
ObjectiveRuntime.lua

Role:
- Runtime container for an objective entity.
- Tracks health and destruction state.

Owns:
- Current health.
- Alive/destroyed flag.

Does NOT:
- Decide targeting.
- Apply damage math.
- Control battle flow.

Rules:
- Damage applied via StatResolver only.
- No global state mutation.
- Deterministic state transitions.

Used By:
- BattleService
- StatResolver
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HealthBarStyle = require(game.ReplicatedStorage.Shared.Presentation.HealthBarStyle)


local ObjectiveRuntime = {}
ObjectiveRuntime.__index = ObjectiveRuntime


function ObjectiveRuntime.new(id, model, config, teamId)
	assert(id)
	assert(model and model.PrimaryPart)
	assert(config.MaxHealth)

	local self = setmetatable({}, ObjectiveRuntime)

	self.Id = id
	self.Model = model
	self.Root = model.PrimaryPart
	self.Config = config
	self.ResolvedStats = config

	self.Team = teamId or "Neutral"
	self.MaxHealth = config.MaxHealth
	self.Health = config.MaxHealth
	self.IsAlive = true

	local gui = ReplicatedStorage.UI.HealthBar:Clone()
	gui.Parent = self.Root

	gui.StudsOffset = Vector3.new(0, HealthBarStyle.Objective.HeightOffset, 0)

	gui.Size = UDim2.new(
		gui.Size.X.Scale * HealthBarStyle.Objective.WidthScale,
		gui.Size.X.Offset * HealthBarStyle.Objective.WidthScale,
		gui.Size.Y.Scale,
		gui.Size.Y.Offset
	)

	self.HealthGui = gui
	self.HealthBar = gui.Bar
	
	self.HealthBar.BackgroundColor3 =
		HealthBarStyle.TeamColors[self.Team] or HealthBarStyle.TeamColors.Neutral

	self:UpdateHealthBar()

	return self
end

function ObjectiveRuntime:TakeDamage(amount)
	if not self.IsAlive then return end

	self.Health -= amount
	self:UpdateHealthBar()

	if self.Health <= 0 then
		self.Health = 0
		self:Die()
	end
end

function ObjectiveRuntime:UpdateHealthBar()
	if not self.HealthBar then return end

	local frac = math.clamp(self.Health / self.MaxHealth, 0, 1)
	self.HealthBar.Size = UDim2.new(frac, 0, 1, 0)
end

function ObjectiveRuntime:Die()
	if not self.IsAlive then return end
	self.IsAlive = false

	if self.HealthGui then
		self.HealthGui:Destroy()
	end

	self.Model:Destroy()
end

return ObjectiveRuntime
