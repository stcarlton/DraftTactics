--[[
UnitRuntime.lua

Role:
- Owns mutable per-unit runtime state.
- Executes Brain intent.
- Drives animation + action state.

Owns:
- Health, cooldowns, ammo.
- ResolvedStats (per-frame).
- Current Intent + targets.

Does NOT:
- Decide strategy (Brain).
- Move character directly (MovementController).
- Compute damage math (StatResolver).
- Coordinate other units.

Invariants:
- Stats resolved once per frame.
- Only mutates its own state.
- Damage applied only via StatResolver.
- Update order must remain deterministic.

Collaborators:
- Brain
- MovementController
- FireController
- StatResolver
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Intent = require(ReplicatedStorage.Shared.Types.Intent)
local ReloadPhase = require(ReplicatedStorage.Shared.Types.ReloadPhase)
local TowerPhase = require(ReplicatedStorage.Shared.Types.TowerPhase)
local Decision = require(ReplicatedStorage.Shared.Types.Decision)
local StatResolver = require(ReplicatedStorage.Shared.Combat.StatResolver)
local Helpers = require(ReplicatedStorage.Shared.Util.Helpers)

local BattlefieldCover = require(script.Parent.BattlefieldCover)
local MovementController = require(script.Parent.MovementController)
local FireController = require(script.Parent.FireController)

local UnitRuntime = {}
UnitRuntime.__index = UnitRuntime

local DebugState = game.ReplicatedStorage
	:WaitForChild("State")
	:WaitForChild("DebugStateValue")
	.Value

function UnitRuntime.new(id, model, config, brain)
	assert(id, "UnitRuntime.new: id is required")
	assert(model, "UnitRuntime.new: model is required")
	assert(config, "UnitRuntime.new: config is required")
	assert(brain, "UnitRuntime.new: brain is required")

	local self = setmetatable({}, UnitRuntime)

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animator = humanoid:FindFirstChildOfClass("Animator")
	
	self.Id = id
	self.Model = model
	self.Root = model.PrimaryPart
	self.Config = config
	self.Brain = brain

	self.Team = nil
	self.AllUnits = nil
	self.Strategy = nil
	self.MaxHealth = config.MaxHealth
	self.Health = config.MaxHealth
	self.IsAlive = true
	self.FireCooldown = 0
	self.MagSize = config.MagSize or 30
	self.AmmoInMag = self.MagSize
	self.HealthBar = nil
	self.FriendlyObjective = nil
	self.EnemyObjective = nil
	self.ResolvedStats = nil
	self.Stealth = false
	self.AmbushTime = config.AmbushTime
	self.TowerAssignment = nil
	self.SharedState = nil

	self.KnownEnemies = {}
	self.AvailableTargets = {}
	self.TargetedBy = {}
	self.ChargedBy = {}
	self.AvailableChargeTargets = {}
	self.AvailableMeleeTargets = {}
	self.KnownInboundEnemies = {}
	self.StealthFriendsMoving = {}
	
	self.Intent = Intent.None
	self.Decision = Decision.None
	self.CurrentTarget  = nil
	self.CurrentChargeTarget = nil
	self.MoveDestination = Vector3.zero
	
	self.AssignedCoverNode = nil
	self.FireCooldown = 0
	
	self.ReloadPhase = ReloadPhase.None
	self.TowerPhase = TowerPhase.None
	
	self.Animator = animator
	self.Anims = {
		StandIdle = animator:LoadAnimation(model.Animations.StandIdle),
		Run  = animator:LoadAnimation(model.Animations.Run),
		Fire = animator:LoadAnimation(model.Animations.Fire),
		CrouchEnter = animator:LoadAnimation(model.Animations.CrouchEnter),
		CrouchIdle = animator:LoadAnimation(model.Animations.CrouchIdle),
		CrouchExit = animator:LoadAnimation(model.Animations.CrouchExit),
		CrouchReload = animator:LoadAnimation(model.Animations.CrouchReload),
		Melee = animator:LoadAnimation(model.Animations.Melee),
		Climb = animator:LoadAnimation(model.Animations.Climb),
	}
	
	self.Anims.Fire.Looped = false
	self.Anims.CrouchReload.Looped = false

	self.Anims.CrouchIdle.Priority		= Enum.AnimationPriority.Idle
	self.Anims.Run.Priority       		= Enum.AnimationPriority.Movement
	self.Anims.CrouchEnter.Priority		= Enum.AnimationPriority.Action
	self.Anims.CrouchExit.Priority  	= Enum.AnimationPriority.Action
	self.Anims.Fire.Priority        	= Enum.AnimationPriority.Action
	self.Anims.CrouchReload.Priority	= Enum.AnimationPriority.Action
	self.Anims.Melee.Priority        	= Enum.AnimationPriority.Action
	self.Anims.Climb.Priority        	= Enum.AnimationPriority.Movement

	self.Anims.StandIdle:Play()
	self:UpdateHealthBar()
	
	if DebugState then
		local debugGui = Instance.new("BillboardGui")
		debugGui.Name = "Debug"
		debugGui.Size = UDim2.fromOffset(120, 30)
		debugGui.StudsOffset = Vector3.new(0, 4, 0) -- above head
		debugGui.AlwaysOnTop = true
		debugGui.MaxDistance = 200

		debugGui.Parent = self.Root

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.3
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Text = "None"

		label.Parent = debugGui

		self._DebugLabel = label
	end
	
	return self
end

function UnitRuntime:Update(dt)
	if not self.IsAlive then return end
	
	if DebugState and self._DebugLabel then
		local colorBy = {
			None           = Color3.fromRGB(180, 180, 180),
			Melee          = Color3.fromRGB(220, 70, 70),
			Charge         = Color3.fromRGB(255, 120, 60),
			Hold           = Color3.fromRGB(90, 160, 140),
			SeekObjective  = Color3.fromRGB(255, 170, 60),
			Destroy        = Color3.fromRGB(255, 90, 40),
			SeekEnemy      = Color3.fromRGB(200, 120, 120),
			Engage         = Color3.fromRGB(255, 60, 60),
			Reposition     = Color3.fromRGB(120, 180, 255),
			TakeCover      = Color3.fromRGB(80, 140, 200),
			Plan           = Color3.fromRGB(170, 140, 220),
			TakeTower 	= Color3.fromRGB(140, 200, 120),
		}


		--local text = tostring(self.Stealth)
		local text = tostring(self.Decision)
		--local text = tostring(self.Intent)
		--local text = tostring(self.ResolvedStats.MoveSpeed)

		self._DebugLabel.Text = text
		self._DebugLabel.TextColor3 = colorBy[text] or Color3.new(1,1,1)
	end
	
	self.ResolvedStats = StatResolver.GetUnitStats(self)
	self.Brain.Update(self, dt)

	if self.ReloadPhase ~= ReloadPhase.None then
		self:AdvanceReloadSequence()
		return
	end

	self:TickReload(dt)
	self:TickMovement(dt)
	self:TickFire(dt)
	self:TickMelee(dt)
	self:TickClimb(dt)
	self:TickHold(dt)
end

function UnitRuntime:TickFire(dt)
	if self.Intent == Intent.Fire then
		FireController.TickFire[self.Config.Class](self, dt)
	end
end

function UnitRuntime:TickMovement(dt)
	if self.Intent == Intent.Move then
		MovementController:MoveUnit(self, dt)
		if not self.Anims.Run.IsPlaying then
			if self.Anims.StandIdle.IsPlaying then
				self.Anims.StandIdle:Stop()
			end
			self.Anims.Run:Play()
		end
	else
		MovementController:Face(self)
	end
end

function UnitRuntime:TickReload(dt)
	if self.Intent == Intent.Reload and self.ReloadPhase == ReloadPhase.None then
		self.Anims.StandIdle:Stop()
		self.Anims.Run:Stop()
		self.Anims.CrouchEnter:Play()
		self.ReloadPhase = ReloadPhase.CrouchEnter
	end
end

function UnitRuntime:AdvanceReloadSequence()
	if self.ReloadPhase == ReloadPhase.CrouchEnter then
		if not self.Anims.CrouchEnter.IsPlaying then
			self.Anims.CrouchReload:Play()
			self.ReloadPhase = ReloadPhase.CrouchReload
		end
	elseif self.ReloadPhase == ReloadPhase.CrouchReload then
		if not self.Anims.CrouchReload.IsPlaying then
			self.Anims.CrouchExit:Play()
			self.ReloadPhase = ReloadPhase.CrouchExit
		end
	elseif self.ReloadPhase == ReloadPhase.CrouchExit then
		if not self.Anims.CrouchExit.IsPlaying then
			self.AmmoInMag = self.MagSize
			self.ReloadPhase = ReloadPhase.None
			self.Anims.StandIdle:Play()
		end
	end
end

function UnitRuntime:TickMelee(dt)
	if self.Intent == Intent.Melee then
		if not self.Anims.Melee.IsPlaying then
			self.Anims.Melee:Play()
			self.Anims.Melee:GetMarkerReachedSignal("Strike"):Once(function()
				self:Melee()
			end)
		end
	end
end

function UnitRuntime:TickClimb(dt)
	if self.Intent == Intent.Climb then
		MovementController:ClimbUnit(self, dt)
		if not self.Anims.Climb.IsPlaying then
			self.Anims.Climb:Play()
		end
	end
end

function UnitRuntime:TickHold(dt)
	if self.Intent == Intent.Hold then
		self.Anims.Run:Stop()
		self.Anims.StandIdle:Play()
	end
end

function UnitRuntime:UpdatePerception(allUnits)
	table.clear(self.KnownEnemies)
	table.clear(self.AvailableTargets)
	table.clear(self.AvailableMeleeTargets)
	table.clear(self.AvailableChargeTargets)
	table.clear(self.TargetedBy)
	table.clear(self.KnownInboundEnemies)
	table.clear(self.StealthFriendsMoving)
	table.clear(self.ChargedBy)

	for _, other in ipairs(allUnits) do
		if other ~= self and other.IsAlive and other.Team ~= self.Team then
			local compare = other.Root.Position - self.Root.Position
			local dist = compare.Magnitude
			
			if dist <= self.ResolvedStats.VisionRange and dist <= other.ResolvedStats.DetectionRange then
				self.KnownEnemies[other] = true
				
				if other.CurrentTarget == self then
					self.TargetedBy[other] = true
				end
				
				if other.CurrentChargeTarget == self then
					self.ChargedBy[other] = true
				end
				
				local chargedBy = next(other.ChargedBy)
				if dist <= self:GetChargeRange() and other:CanCharge() and (not chargedBy or chargedBy == self) then
					if self.SharedState.PreEngagement then
						self.SharedState.PreEngagement = false
					end
					self.AvailableChargeTargets[other] = true
				end

				if other.Intent == Intent.Move then
					if Helpers.IsFacing(other.Root.Position, other.Root.CFrame.LookVector, self.Root.Position) then
						self.KnownInboundEnemies[other] = true
					end
				end
				local preEngagementAdj = 0
				if self.SharedState.PreEngagement and not self.AssignedCoverNode then
					preEngagementAdj = 30
				end
				if dist <= (self.ResolvedStats.FireRange - preEngagementAdj) then
					self.AvailableTargets[other] = true
				end
			end
			if dist <= self.ResolvedStats.MeleeRange 
				and (self.Intent == Intent.Move or self.Intent == Intent.Melee) 
				and Helpers.IsFacing(self.Root.Position, self.Root.CFrame.LookVector, other.Root.Position) then
				self.AvailableMeleeTargets[other] = true
			end
		end
	end
	
	if self.Stealth and self.SharedState.PreEngagement then
		for _, friend in ipairs(allUnits) do
			if friend ~= self and friend.IsAlive and friend.Team == self.Team and friend.Stealth and friend.Intent == Intent.Move then
				self.StealthFriendsMoving[friend] = true
			end
		end
	end

end

---------------------------------------------------------------------
-- Combat
---------------------------------------------------------------------

function UnitRuntime:Melee()
	local enemy = self.CurrentTarget
	if not enemy or not enemy.IsAlive then return end
	StatResolver.ResolveMelee(self, enemy)
end

function UnitRuntime:HasBullet()
	return self.AmmoInMag > 0
end

function UnitRuntime:CanCharge()
	return not self.TowerAssignment
end

function UnitRuntime:GetChargeRange()
	return self.ResolvedStats.MoveSpeed * 2
end

function UnitRuntime:TakeDamage(amount)
	if not self.IsAlive then return end

	self.Health -= amount
	self:UpdateHealthBar()

	if self.Health <= 0 then
		self.Health = 0
		self:Die()
	end
end

function UnitRuntime:UpdateHealthBar()
	if not self.HealthBar then return end

	local frac = math.clamp(self.Health / self.MaxHealth, 0, 1)
	self.HealthBar.Size = UDim2.new(frac, 0, 1, 0)
end

---------------------------------------------------------------------
-- Death
---------------------------------------------------------------------
function UnitRuntime:Die()
	if not self.IsAlive then return end
	BattlefieldCover:UnReserve(self)

	self.IsAlive = false

	local gui = self.Model:FindFirstChild("HealthBar", true)
	if gui and gui:IsA("BillboardGui") then
		gui:Destroy()
	end
	
	self.HealthBar = nil
	
	if DebugState then
		self._DebugLabel.Text = ""
	end

	self:DropWeapon()
	self:EnableRagdoll()
end

function UnitRuntime:DropWeapon()
	local weapon =
		self.Model:FindFirstChild("Handle", true)
		or self.Model:FindFirstChild("Weapon", true)

	if not weapon then
		return
	end

	for _, obj in ipairs(weapon:GetDescendants()) do
		if obj:IsA("WeldConstraint") or obj:IsA("Motor6D") then
			obj:Destroy()
		end
	end

	weapon.Parent = workspace

	if weapon:IsA("BasePart") then
		weapon.Anchored = false
		weapon.CanCollide = true
		weapon.Massless = false
	else
		if weapon.PrimaryPart then
			weapon.PrimaryPart.Anchored = false
		end

		for _, part in ipairs(weapon:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
				part.Massless = false
			end
		end
	end

	if weapon:IsA("Model") and weapon.PrimaryPart then
		weapon.PrimaryPart.AssemblyLinearVelocity =
			self.Root.CFrame.LookVector * 2 + Vector3.new(0, 3, 0)
	elseif weapon:IsA("BasePart") then
		weapon.AssemblyLinearVelocity =
			self.Root.CFrame.LookVector * 2 + Vector3.new(0, 3, 0)
	end
end

function UnitRuntime:EnableRagdoll()
	local humanoid = self.Model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		humanoid.PlatformStand = true
	end

	self.Root.Anchored = false
	self.Root.CanCollide = false
	self.Root.Massless = true
	self.Root.AssemblyLinearVelocity = Vector3.zero
	self.Root.AssemblyAngularVelocity = Vector3.zero

	for _, joint in ipairs(self.Model:GetDescendants()) do
		if joint:IsA("Motor6D") then
			local p0, p1 = joint.Part0, joint.Part1
			if p0 and p1 then
				local a0 = Instance.new("Attachment")
				a0.CFrame = joint.C0
				a0.Parent = p0

				local a1 = Instance.new("Attachment")
				a1.CFrame = joint.C1
				a1.Parent = p1

				local socket = Instance.new("BallSocketConstraint")
				socket.Attachment0 = a0
				socket.Attachment1 = a1
				socket.LimitsEnabled = true
				socket.UpperAngle = 30
				socket.Parent = joint.Parent
			end

			joint.Enabled = false
		end
	end

	for _, part in ipairs(self.Model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = (part ~= self.Root)
			part.Massless = (part == self.Root)
		end
	end

	local function findPart(...)
		for i = 1, select("#", ...) do
			local name = select(i, ...)
			local p = self.Model:FindFirstChild(name, true)
			if p and p:IsA("BasePart") then
				return p
			end
		end
		return nil
	end

	local leftArm  = findPart("Left Arm", "LeftArm")
	local rightArm = findPart("Right Arm", "RightArm")

	local function randf(a, b)
		return a + (b - a) * math.random()
	end

	local function nudgeArm(arm, sideSign)
		if not arm then return end

		local spin = Vector3.new(
			randf(-1.5, 1.5),
			randf(-2.0, 2.0),
			randf(-3.0, 3.0) * sideSign
		)

		local shove = Vector3.new(
			randf(0.5, 1.2) * sideSign,
			randf(0.0, 0.6),
			randf(-0.3, 0.6)
		)

		arm.AssemblyAngularVelocity += spin
		arm.AssemblyLinearVelocity  += shove
	end

	nudgeArm(leftArm,  -1)
	nudgeArm(rightArm,  1)
end

return UnitRuntime