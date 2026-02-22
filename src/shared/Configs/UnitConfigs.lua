-- UnitConfigs.lua

local Class = require(game.ReplicatedStorage.Shared.Types.Class)

local UnitConfigs = {}

---------------------------------------------------------------------
-- Global tuning constants (shared across all infantry)
---------------------------------------------------------------------

local INFANTRY_MOVE_SPEED = 17
local INFANTRY_MAX_HEALTH = 1000
local INFANTRY_DAMAGE = 10
local INFANTRY_MELEE_DAMAGE = 350
local INFANTRY_FIRE_RATE = 10        -- shots per second
local INFANTRY_FIRE_RANGE = 100       -- distance at which unit can fire
local INFANTRY_VISION_RANGE = 150     -- how far the unit can perceive enemies
local INFANTRY_DETECTION_RANGE = 400  -- how far enemies can perceive this unit
local INFANTRY_MELEE_RANGE = 6		  -- how far before unit will automatically melee
local INFANTRY_CLIMB_SPEED = 6
local INFANTRY_COVER_REDUCTION = 0.5
local INFANTRY_AMBUSH_TIME = 3
local INFANTRY_DAMAGE_REDUCTION = 0
local INFANTRY_MAG_SIZE = 30

---------------------------------------------------------------------
-- Infantry
---------------------------------------------------------------------

UnitConfigs.Infantry = {
	Class = Class.Infantry,

	MaxHealth = INFANTRY_MAX_HEALTH,
	MoveSpeed = INFANTRY_MOVE_SPEED,
	Damage = INFANTRY_DAMAGE,
	MeleeDamage = INFANTRY_MELEE_DAMAGE,
	FireRate = INFANTRY_FIRE_RATE,
	FireRange = INFANTRY_FIRE_RANGE,
	VisionRange = INFANTRY_VISION_RANGE,
	DetectionRange = INFANTRY_DETECTION_RANGE,
	MeleeRange = INFANTRY_MELEE_RANGE,
	ClimbSpeed = INFANTRY_CLIMB_SPEED,
	DamageReduction = INFANTRY_DAMAGE_REDUCTION,
	CoverReduction = INFANTRY_COVER_REDUCTION,
	AmbushTime = INFANTRY_AMBUSH_TIME,
	MagSize = INFANTRY_MAG_SIZE,
	Stealth = false,
}

---------------------------------------------------------------------
-- Sniper
---------------------------------------------------------------------

local SNIPER_MOVE_SPEED = 15
local SNIPER_MAX_HEALTH = 1000
local SNIPER_DAMAGE = 1000
local SNIPER_MELEE_DAMAGE = 350
local SNIPER_FIRE_RATE = 0.15        -- shots per second
local SNIPER_FIRE_RANGE = 200       -- distance at which unit can fire
local SNIPER_VISION_RANGE = 300     -- how far the unit can perceive enemies
local SNIPER_DETECTION_RANGE = 400  -- how far enemies can perceive this unit
local SNIPER_MELEE_RANGE = 6		  -- how far before unit will automatically melee
local SNIPER_CLIMB_SPEED = 6
local SNIPER_COVER_REDUCTION = 0.5
local SNIPER_AMBUSH_TIME = 3
local SNIPER_DAMAGE_REDUCTION = 0
local SNIPER_MAG_SIZE = 6

UnitConfigs.Sniper = {
	Class = Class.Sniper,
	
	MaxHealth = SNIPER_MAX_HEALTH,
	MoveSpeed = SNIPER_MOVE_SPEED,
	Damage = SNIPER_DAMAGE,
	MeleeDamage = SNIPER_MELEE_DAMAGE,
	FireRate = SNIPER_FIRE_RATE,
	FireRange = SNIPER_FIRE_RANGE,
	VisionRange = SNIPER_VISION_RANGE,
	DetectionRange = SNIPER_DETECTION_RANGE,
	MeleeRange = SNIPER_MELEE_RANGE,
	ClimbSpeed = SNIPER_CLIMB_SPEED,
	DamageReduction = SNIPER_DAMAGE_REDUCTION,
	CoverReduction = SNIPER_COVER_REDUCTION,
	AmbushTime = SNIPER_AMBUSH_TIME,
	MagSize = SNIPER_MAG_SIZE,
	Stealth = false,
}

return UnitConfigs
