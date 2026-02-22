-- HealthBarStyle.lua
-- Shared presentation constants for health bars

local HealthBarStyle = {}

HealthBarStyle.TeamColors = {
	A = Color3.fromRGB(60, 220, 60),
	B = Color3.fromRGB(220, 60, 60),
	Neutral = Color3.fromRGB(200, 200, 200),
}

HealthBarStyle.Unit = {
	HeightOffset = 6,
	WidthScale = 1.0,
}

HealthBarStyle.Objective = {
	HeightOffset = 14,
	WidthScale = 2.5,
}

return HealthBarStyle
