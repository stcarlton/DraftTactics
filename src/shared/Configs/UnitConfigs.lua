-- UnitConfigs.lua
-- Static archetype stats for each unit class.

local Class = require(game.ReplicatedStorage.Shared.Types.Class)

local UnitConfigs = {}

---------------------------------------------------------------------
-- Infantry
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
local INFANTRY_RELOAD_TIME = 2

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
	ReloadTime = INFANTRY_RELOAD_TIME,
	Stealth = false,
}

---------------------------------------------------------------------
-- Sniper
---------------------------------------------------------------------

local SNIPER_MOVE_SPEED = 15
local SNIPER_MAX_HEALTH = 1000
local SNIPER_DAMAGE = 1000
local SNIPER_MELEE_DAMAGE = 350
local SNIPER_FIRE_RATE = (1/3)        -- shots per second
local SNIPER_FIRE_RANGE = 200       -- distance at which unit can fire
local SNIPER_VISION_RANGE = 300     -- how far the unit can perceive enemies
local SNIPER_DETECTION_RANGE = 400  -- how far enemies can perceive this unit
local SNIPER_MELEE_RANGE = 6		  -- how far before unit will automatically melee
local SNIPER_CLIMB_SPEED = 6
local SNIPER_COVER_REDUCTION = 0.5
local SNIPER_AMBUSH_TIME = 3
local SNIPER_DAMAGE_REDUCTION = 0
local SNIPER_RELOAD_TIME = 2
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
	ReloadTime = SNIPER_RELOAD_TIME,
	Stealth = false,
}

---------------------------------------------------------------------
-- Commando
---------------------------------------------------------------------

local COMMANDO_MOVE_SPEED = 15
local COMMANDO_MAX_HEALTH = 1000
local COMMANDO_DAMAGE = 1000
local COMMANDO_MELEE_DAMAGE = 350
local COMMANDO_FIRE_RATE = (1/3)        -- shots per second
local COMMANDO_FIRE_RANGE = 200       -- distance at which unit can fire
local COMMANDO_VISION_RANGE = 300     -- how far the unit can perceive enemies
local COMMANDO_DETECTION_RANGE = 400  -- how far enemies can perceive this unit
local COMMANDO_MELEE_RANGE = 6		  -- how far before unit will automatically melee
local COMMANDO_CLIMB_SPEED = 6
local COMMANDO_COVER_REDUCTION = 0.5
local COMMANDO_AMBUSH_TIME = 3
local COMMANDO_DAMAGE_REDUCTION = 0
local COMMANDO_RELOAD_TIME = 2
local COMMANDO_MAG_SIZE = 6

UnitConfigs.Commando = {
	Class = Class.Commando,
	MaxHealth = COMMANDO_MAX_HEALTH,
	MoveSpeed = COMMANDO_MOVE_SPEED,
	Damage = COMMANDO_DAMAGE,
	MeleeDamage = COMMANDO_MELEE_DAMAGE,
	FireRate = COMMANDO_FIRE_RATE,
	FireRange = COMMANDO_FIRE_RANGE,
	VisionRange = COMMANDO_VISION_RANGE,
	DetectionRange = COMMANDO_DETECTION_RANGE,
	MeleeRange = COMMANDO_MELEE_RANGE,
	ClimbSpeed = COMMANDO_CLIMB_SPEED,
	DamageReduction = COMMANDO_DAMAGE_REDUCTION,
	CoverReduction = COMMANDO_COVER_REDUCTION,
	AmbushTime = COMMANDO_AMBUSH_TIME,
	MagSize = COMMANDO_MAG_SIZE,
	ReloadTime = COMMANDO_RELOAD_TIME,
	Stealth = false,
}

---------------------------------------------------------------------
-- DEMOLITIONIST
---------------------------------------------------------------------

local DEMOLITIONIST_MOVE_SPEED = 15
local DEMOLITIONIST_MAX_HEALTH = 1000
local DEMOLITIONIST_DAMAGE = 1000
local DEMOLITIONIST_MELEE_DAMAGE = 350
local DEMOLITIONIST_FIRE_RATE = (1/3)        -- shots per second
local DEMOLITIONIST_FIRE_RANGE = 200       -- distance at which unit can fire
local DEMOLITIONIST_VISION_RANGE = 300     -- how far the unit can perceive enemies
local DEMOLITIONIST_DETECTION_RANGE = 400  -- how far enemies can perceive this unit
local DEMOLITIONIST_MELEE_RANGE = 6		  -- how far before unit will automatically melee
local DEMOLITIONIST_CLIMB_SPEED = 6
local DEMOLITIONIST_COVER_REDUCTION = 0.5
local DEMOLITIONIST_AMBUSH_TIME = 3
local DEMOLITIONIST_DAMAGE_REDUCTION = 0
local DEMOLITIONIST_RELOAD_TIME = 2
local DEMOLITIONIST_MAG_SIZE = 6

UnitConfigs.Demolitionist = {
	Class = Class.Demolitionist,
	MaxHealth = DEMOLITIONIST_MAX_HEALTH,
	MoveSpeed = DEMOLITIONIST_MOVE_SPEED,
	Damage = DEMOLITIONIST_DAMAGE,
	MeleeDamage = DEMOLITIONIST_MELEE_DAMAGE,
	FireRate = DEMOLITIONIST_FIRE_RATE,
	FireRange = DEMOLITIONIST_FIRE_RANGE,
	VisionRange = DEMOLITIONIST_VISION_RANGE,
	DetectionRange = DEMOLITIONIST_DETECTION_RANGE,
	MeleeRange = DEMOLITIONIST_MELEE_RANGE,
	ClimbSpeed = DEMOLITIONIST_CLIMB_SPEED,
	DamageReduction = DEMOLITIONIST_DAMAGE_REDUCTION,
	CoverReduction = DEMOLITIONIST_COVER_REDUCTION,
	AmbushTime = DEMOLITIONIST_AMBUSH_TIME,
	MagSize = DEMOLITIONIST_MAG_SIZE,
	ReloadTime = DEMOLITIONIST_RELOAD_TIME,
	Stealth = false,
}

return UnitConfigs
