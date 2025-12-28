--- Global PVP manager for players.
--- Dependencies: instashield.lua, downed.lua

local instaShieldCooldown = 35

--- @param player player_t
addHook("PlayerThink", function(player)
	local gametype = FH:isMode()

	if not gametype then return end
	if not player.heistRound then return end

	if FHR.currentState == "game"
	and player.mo
	and player.mo.health
	and not P_PlayerInPain(player)
	and player.cmd.buttons & BT_ATTACK > 0
	and player.lastbuttons & BT_ATTACK == 0
	and not player.heistRound.instaShieldCooldown
	and player.heistRound.canUseInstaShield then
		FH:useInstaShield(player.mo)
		player.heistRound.instaShieldCooldown = instaShieldCooldown
	end

	if player.heistRound.instaShieldCooldown then
		player.heistRound.instaShieldCooldown = $ - 1

		if not player.heistRound.instaShieldCooldown and player.mo then
			S_StartSoundAtVolume(player.mo, sfx_s3k41, 55)
			S_StartSoundAtVolume(player.mo, sfx_s3k44, 55)

			local ghost = P_SpawnGhostMobj(player.mo)
			ghost.fuse = 12
			ghost.destscale = 10 * FU
		end
	end
end)

addHook("ShouldDamage", function(targ, inf, source)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end

	if FHR.currentState ~= "game" then return false end

	-- TODO: friendlyfire checks from the gamemode and the cvar
	if source and source.valid and source.type == MT_PLAYER then
		if not source.player then return end
		if not source.player.heistRound then return end
		if source.player[pw_flashing] then return end
		if source.player[pw_invulnerability] then return end
		if source.player[pw_super] then return end
		if source.player.powers[pw_strong] & STR_GUARD then return false end
		if source.player.heistRound.downed then return false end

		return true
	end
end, MT_PLAYER)