-- ModifierStack.lua

local StatOp = require(script.Parent.StatOp)

local ModifierStack = {}
ModifierStack.__index = ModifierStack

function ModifierStack.new()
	return setmetatable({
		Mods = {}
	}, ModifierStack)
end

function ModifierStack:Add(mod)
	table.insert(self.Mods, mod)
end

function ModifierStack:ApplyTo(baseStats, context)
	local result = {}

	for k, v in pairs(baseStats) do
		result[k] = v
	end

	for _, mod in ipairs(self.Mods) do
		if mod.Op == StatOp.Add then
			result[mod.Stat] += mod.Value
		elseif mod.Op == StatOp.Mul then
			result[mod.Stat] *= mod.Value
		elseif mod.Op == StatOp.Perc then
			result[mod.Stat] *= (mod.Value / 100)
		elseif mod.Op == StatOp.Set then
			result[mod.Stat] = mod.Value
		end
	end

	return result
end

return ModifierStack
