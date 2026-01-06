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

--- Sets the player's health. If set to zero, the player will be downed. Anything below zero will turn the player invincible, and anything above the player's max health acts as overheal. If this returns true, the player has been downed.
--- @param player player_t
--- @param health fixed_t
--- @return boolean
function FH:setHealth(player, health)
	player.heistRound.health = health

	if player.heistRound.health == 0 then
		FH:downPlayer(player, 10 * TICRATE)
		return true
	end

	return false
end

---@param player player_t
---@param time tic_t
function FH:downPlayer(player, time)
	if FHR.currentState ~= "game" then return end

	player.mo.state = S_FH_PLAY_DOWNED

	player.heistRound.downed = true
	player.heistRound.downedTime = time or 0
	player.heistRound.canUseInstaShield = false
	player.heistRound.canUseBlock = false

	for i = #player.heistRound.collectibles, 1, -1 do
		FH:dropCollectible(player, player.heistRound.collectibles[i])
	end

	player.powers[pw_flashing] = 2
	player.normalspeed = skins[player.skin].normalspeed / 5
	player.acceleration = $ / 2
	player.accelstart = $ / 2

	FH:playerStopBlock(player)
	FH:setPlayerExpression(player, "dead")

	S_StartSound(player.mo, sfx_kc31)
	S_StartSound(player.mo, sfx_nghurt)
	S_StartSound(player.mo, sfx_s3k6d)

	-- TODO: cheap check, add more functions to heistGametype_t to get when the player gets downed and put this in there
	local gametype = FH:isMode()
	if not gametype then return end

	gametype:safeFinish()
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
	player.heistRound.canUseBlock = true

	FH:setHealth(player, FH.characterHealths[player.mo.skin])
	FH:setPlayerExpression(player, "default")

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