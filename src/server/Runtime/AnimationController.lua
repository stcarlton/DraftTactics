--[[
AnimationController.lua

Role:
- Applies animation playback from unit state.
- Purely visual; must not drive simulation timing.

Used By:
- UnitRuntime
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Intent = require(ReplicatedStorage.Shared.Types.Intent)

local AnimationController = {}

local function play(track, fadeTime, weight, speed)
	if not track then
		return
	end

	if speed then
		track:Play(fadeTime or 0.1, weight or 1, speed)
		return
	end

	if not track.IsPlaying then
		track:Play(fadeTime or 0.1, weight or 1)
	end
end

local function stop(track, fadeTime)
	if track and track.IsPlaying then
		track:Stop(fadeTime or 0.1)
	end
end

function AnimationController:Update(unit, dt)
	local _ = dt
	if not unit.IsAlive then
		return
	end

	local anims = unit.Anims
	local events = unit.VisualEvents

	if events.StartReload then
		stop(anims.StandIdle, 0.05)
		stop(anims.Run, 0.05)
		play(anims.Reload, 0.1, 1, unit.VisualState.ReloadPlaybackSpeed)
	end

	if events.StartMelee then
		play(anims.Melee, 0.05, 1, unit.VisualState.MeleePlaybackSpeed)
	end

	if events.Fired then
		stop(anims.StandIdle, 0.02)
		stop(anims.Run, 0.02)
		play(anims.Fire, 0.02, 1)
	end

	if unit.IsReloading then
		stop(anims.Run)
		stop(anims.Climb)
		return
	end

	if unit.Intent == Intent.Climb then
		stop(anims.Run)
		stop(anims.StandIdle)
		play(anims.Climb, 0.05, 1)
		return
	end

	stop(anims.Climb)

	if unit.Intent == Intent.Move then
		stop(anims.StandIdle)
		play(anims.Run, 0.05, 1)
		return
	end

	stop(anims.Run)
	if not anims.Fire.IsPlaying and not anims.Melee.IsPlaying and not anims.Reload.IsPlaying then
		play(anims.StandIdle, 0.1, 1)
	end
end

return AnimationController
