freeslot("S_FH_PLAY_DOWNED")

---@diagnostic disable-next-line: missing-fields
states[S_FH_PLAY_DOWNED] = {
	sprite = SPR_PLAY,
	frame = SPR2_PAIN,
	tics = -1,
	---@diagnostic disable-next-line: assign-type-mismatch
	action = nil,
	var1 = 0,
	var2 = 0,
	nextstate = S_FH_PLAY_DOWNED
}

---@param player player_t
---@param time tic_t
function FH:downPlayer(player, time)
	if FHR.currentState ~= "game" then return end

	player.mo.state = S_FH_PLAY_DOWNED

	player.heistRound.downed = true
	player.heistRound.downedTime = time or 0
	player.heistRound.canUseInstaShield = false

	player.powers[pw_flashing] = 2
	player.normalspeed = skins[player.skin].normalspeed / 5
	player.acceleration = $ / 2
	player.accelstart = $ / 2

	S_StartSound(player.mo, sfx_kc31)
	S_StartSound(player.mo, sfx_nghurt)
	S_StartSound(player.mo, sfx_s3k6d)

	print("downed player")
end

---@param player player_t
function FH:revivePlayer(player)
	if FHR.currentState ~= "game" then return end
	if not player.heistRound.downed then return end
	
	player.mo.state = S_PLAY_STND
	player.powers[pw_flashing] = 2 * TICRATE

	player.heistRound.downed = false
	player.heistRound.downedTime = 0
	player.heistRound.canUseInstaShield = true
	player.heistRound.health = FH.characterHealths[player.mo.skin]

	player.normalspeed = skins[player.skin].normalspeed
	player.acceleration = skins[player.skin].acceleration
	player.accelstart = skins[player.skin].accelstart

	S_StartSound(player.mo, sfx_s3k38)
end

---@param player player_t
addHook("PlayerThink", function(player)
	if not FH:isMode() then return end
	if not player.mo then return end
	if not player.heistRound then return end
	if not player.heistRound.downed then return end
	if not player.mo.health then
		FH:revivePlayer(player)
		return
	end

	player.powers[pw_flashing] = 2
	player.pflags = $|PF_JUMPSTASIS
	player.mo.state = S_FH_PLAY_DOWNED

	if player.heistRound.downedTime then
		player.heistRound.downedTime = $ - 1

		if player.heistRound.downedTime == 0 then
			FH:revivePlayer(player)
		end
	end
end)

---@param player mobj_t
---@param inflictor mobj_t
---@param source mobj_t
---@param damagetype integer
addHook("MobjDamage", function(player, inflictor, source, _, damagetype)
	if not FH:isMode() then return end
	if not player.player then return end
	if not player.player.heistRound then return end
	-- if player.player.rings > 0 then return end
	if player.player.powers[pw_shield] then return end
	if player.player.powers[pw_flashing] then return end
	if player.player.powers[pw_invulnerability] then return end
	if player.player.powers[pw_super] then return end

	if (damagetype & DMG_DEATHMASK) then
		player.player.heistRound.health = 0
		return
	end

	player.player.heistRound.health = $ - 25*FU -- NOTE: make stuff do different dmg amounts maybe?
	if player.player.heistRound.health <= 0 then
		player.player.heistRound.health = 0
		FH:downPlayer(player.player, 5 * TICRATE)

		if source
		and source.valid
		and source.type == MT_PLAYER
		and source.player
		and source.player.heistRound then
			FH:addProfit(source.player, FH.profitCVars.playerDeath.value, "Downed "..player.player.name)
		end

		return true
	elseif player.player.rings <= 0 then
		P_DoPlayerPain(player.player, source, inflictor) -- this is all u need for no ring thingies right? we're not gonna have flags or match emeralds
		P_PlayRinglossSound(player, player.player)

		return true
	end
end, MT_PLAYER)

---@param player mobj_t
addHook("ShouldDamage", function(player)
	if not FH:isMode() then return end
	if not player.player then return end
	if not player.player.heistRound then return end

	if player.player.heistRound.downed then
		return false
	end
end, MT_PLAYER)

COM_AddCommand("fh_downplayer", function(player, time)
	FH:downPlayer(player, tonumber(time or "12"))
end, COM_ADMIN)