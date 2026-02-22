--UnitModifiers.lua

local Strategy = require(game.ReplicatedStorage.Shared.Types.Strategy)
local StatOp = require(script.Parent.StatOp)
local Decision = require(game.ReplicatedStorage.Shared.Types.Decision)

local UnitModifiers = {}

function UnitModifiers.ApplyRuntimeModifiers(unit, stack)
	if unit.Strategy == Strategy.Strategy.Blitz then
		stack:Add({
			Stat = "MoveSpeed",
			Op = StatOp.Perc,
			Value = 120,
		})
	end
	
	if unit.Strategy == Strategy.Strategy.Stalk then
		if unit.Strategy == Strategy.Strategy.Defend then
			stack:Add({
				Stat = "Damage",
				Op = StatOp.Perc,
				Value = 105,
			})
		end
	end
	
	if unit.Strategy == Strategy.Strategy.Defend then
		stack:Add({
			Stat = "DamageReduction",
			Op = StatOp.Add,
			Value = 0.05,
		})
	end
	
	if unit.TowerAssignment and unit.TowerAssignment.Tower then
		stack:Add({
			Stat = "VisionRange",
			Op = StatOp.Perc,
			Value = 175,
		})
		
		stack:Add({
			Stat = "DetectionRange",
			Op = StatOp.Perc,
			Value = 120,
		})
		
		stack:Add({
			Stat = "FireRange",
			Op = StatOp.Perc,
			Value = 175,
		})
		
		stack:Add({
			Stat = "Damage",
			Op = StatOp.Perc,
			Value = 110,
		})
		
		stack:Add({
			Stat = "CoverReduction",
			Op = StatOp.Perc,
			Value = 110,
		})
	end
	
	if unit.Stealth then
		stack:Add({
			Stat = "DetectionRange",
			Op = StatOp.Perc,
			Value = 10,
		})
		stack:Add({
			Stat = "Damage",
			Op = StatOp.Perc,
			Value = 250,
		})
		stack:Add({
			Stat = "MoveSpeed",
			Op = StatOp.Perc,
			Value = 80,
		})
	end
	
	if unit.Decision == Decision.Charge then
		stack:Add({
			Stat = "MoveSpeed",
			Op = StatOp.Perc,
			Value = 140,
		})
	end
end

function UnitModifiers.ApplyStaticModifiers(unit, stack)
	if unit.Strategy == Strategy.Strategy.Stalk then
		stack:Add({
			Stat = "Stealth",
			Op = StatOp.Set,
			Value = true,
		})
	end
end

return UnitModifiers
