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
	player.hr.health = health

	if player.hr.health == 0 then
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

	player.hr.downed = true
	player.hr.downedTime = time or 0
	player.hr.canUseInstaShield = false
	player.hr.canUseBlock = false

	for i = #player.hr.collectibles, 1, -1 do
		FH:dropCollectible(player, player.hr.collectibles[i])
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
	if not player.hr.downed then return end
	
	player.mo.state = S_PLAY_STND
	player.powers[pw_flashing] = 2 * TICRATE

	player.hr.downed = false
	player.hr.downedTime = 0
	player.hr.canUseInstaShield = true
	player.hr.canUseBlock = true

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
	if not player.hr then return end
	if not player.hr.downed then return end
	if not player.mo.health then
		FH:revivePlayer(player)
		return
	end

	player.powers[pw_flashing] = 2
	player.pflags = $|PF_JUMPSTASIS
	player.mo.state = S_FH_PLAY_DOWNED

	if player.hr.downedTime then
		player.hr.downedTime = $ - 1

		if player.hr.downedTime == 0 then
			FH:revivePlayer(player)
			return
		end
	end

	for _, member in ipairs(player.hg.team.players) do
		if member == player then continue end
		if not member.mo then continue end
		if not member.mo.health then continue end
		if member.hr.downed then continue end
		if member.hr.escaped then continue end
		if member.hr.spectator then continue end

		local distance = FH:pointTo3DDist(member.mo.x, member.mo.y, member.mo.z, player.mo.x, player.mo.y, player.mo.z)

		if distance <= player.mo.radius + member.mo.radius then
			S_StartSound(member.mo, sfx_s3k4a)
			FH:revivePlayer(player)
			break
		end
	end
end)

---@param player mobj_t
addHook("ShouldDamage", function(player)
	if not FH:isMode() then return end
	if not player.player then return end
	if not player.player.hr then return end

	if player.player.hr.downed then
		return false
	end
end, MT_PLAYER)

COM_AddCommand("fh_downplayer", function(player, time)
	FH:downPlayer(player, tonumber(time or "12"))
end, COM_ADMIN)