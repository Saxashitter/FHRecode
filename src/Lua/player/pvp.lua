--- Global PVP manager for players.
--- Dependencies: instashield.lua, block.lua, downed.lua

local instaShieldCooldown = 35

local blockCooldown = 8
local blockDrainTics = 4 * TICRATE
local blockRegainStrengthTics = 6 * TICRATE
local blockDamage = FU / 4
local blockChargeCooldown = TICRATE

--- @param player player_t
function FH:playerUseBlock(player)
	FH:useBlock(player.mo)
	player.heistRound.blockCooldown = blockCooldown
end

--- @param player player_t
--- @param startCooldowns boolean|nil
function FH:playerStopBlock(player, startCooldowns)
	FH:stopBlock(player.mo)

	if startCooldowns == false then return end

	player.heistRound.blockCooldown = blockCooldown
	player.heistRound.blockChargeCooldown = blockChargeCooldown
end

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
	and player.heistRound.canUseInstaShield
	and not player.mo.fh_block then
		FH:useInstaShield(player.mo)
		player.heistRound.instaShieldCooldown = instaShieldCooldown
	end

	if FHR.currentState == "game"
	and player.mo
	and player.mo.health
	and not P_PlayerInPain(player)
	and player.cmd.buttons & BT_FIRENORMAL > 0
	and player.lastbuttons & BT_FIRENORMAL == 0
	and not player.heistRound.blockCooldown
	and player.heistRound.canUseBlock
	and not player.mo.fh_block
	and not player.mo.fh_instashield then
		FH:playerUseBlock(player)
	end

	if FHR.currentState == "game"
	and player.mo
	and player.mo.health
	and not P_PlayerInPain(player)
	and player.cmd.buttons & BT_FIRENORMAL == 0
	and not player.heistRound.blockCooldown
	and player.mo.fh_block then
		FH:playerStopBlock(player)
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

	if player.heistRound.blockCooldown then
		player.heistRound.blockCooldown = $ - 1
	end

	if player.mo then
		if player.mo.fh_block then
			local t = FixedDiv(player.heistRound.blockStrength, player.heistRound.blockMaxStrength)
			local scale = ease.linear(t, player.mo.scale / 2, player.mo.scale * 3 / 2)
			local block = player.mo.fh_block

			block.scale = scale

			---@diagnostic disable-next-line: assign-type-mismatch
			if player.heistRound.blockStrength > blockDamage
			and player.heistRound.blockStrength - FU / blockDrainTics <= blockDamage then
				-- hey, if you get hit, you are FUCKED
				S_StartSoundAtVolume(player.mo, sfx_s258, 100)
			end
			---@diagnostic disable-next-line: assign-type-mismatch
			player.heistRound.blockStrength = max(0, $ - FU / blockDrainTics)

		elseif player.heistRound.blockChargeCooldown then
			player.heistRound.blockChargeCooldown = $ - 1

			if player.heistRound.blockChargeCooldown == 0 then
				S_StartSound(player.mo, sfx_3db16)
			end

		elseif player.heistRound.blockStrength < player.heistRound.blockMaxStrength then
			---@diagnostic disable-next-line: assign-type-mismatch
			player.heistRound.blockStrength = min(player.heistRound.blockMaxStrength, $ + FU / blockRegainStrengthTics)

			if player.heistRound.blockStrength == player.heistRound.blockMaxStrength then
				S_StartSound(player.mo, sfx_3db06)
			end
		end
	end
end)

addHook("JumpSpecial", function(player)
	if not FH:isMode() then return end
	if not player.heistRound then return end
	if not player.mo then return end
	if player.heistRound.downed then
		return true
	end
end)

addHook("SpinSpecial", function(player)
	if not FH:isMode() then return end
	if not player.heistRound then return end
	if not player.mo then return end
	if player.heistRound.downed then
		return true
	end
end)

addHook("ShouldDamage", function(targ, inf, source)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end

	if FHR.currentState ~= "game" then return false end

	-- TODO: friendlyfire checks from the gamemode and the cvar
	if source and source.valid and source.type == MT_PLAYER then
		if not targ.player then return end
		if not targ.player.heistRound then return end
		if targ.player.powers[pw_flashing] then return false end
		if targ.player.powers[pw_invulnerability] then return false end
		if targ.player.powers[pw_super] then return false end
		if targ.player.powers[pw_strong] & STR_GUARD then return false end
		if targ.player.heistRound.downed then return false end

		return true
	end

	if targ.fh_instashield then
		return false -- TODO: make use of STR_GUARD
	end
end, MT_PLAYER)

---@param player mobj_t
---@param inflictor mobj_t
---@param source mobj_t
---@param damagetype integer
addHook("MobjDamage", function(player, inflictor, source, _, damagetype)
	if not FH:isMode() then return end
	if not player.player then return end
	if not player.player.heistRound then return end

	if player.player.powers[pw_shield] then return end
	if player.player.powers[pw_flashing] then return end
	if player.player.powers[pw_invulnerability] then return end
	if player.player.powers[pw_super] then return end

	local health = max(0, player.player.heistRound.health - 25*FU)

	if (damagetype & DMG_DEATHMASK) then
		health = 0
	elseif player.fh_block then
		--- TODO: slap this in a function
		--- @diagnostic disable-next-line: assign-type-mismatch
		player.player.heistRound.blockStrength = max(0, $ - blockDamage)

		if player.player.heistRound.blockStrength <= blockDamage then
			S_StartSoundAtVolume(player, sfx_s258, 100)
		end
		
		if player.player.heistRound.blockStrength > 0 then
			player.player.powers[pw_flashing] = 16
			S_StartSoundAtVolume(player, sfx_kc40, 60)

			if inflictor and inflictor.valid and inflictor.health and inflictor.flags & MF_MISSILE then
				inflictor.target = player

				FH:knockbackMobj(inflictor, player)
			end

			return true
		end

		FH:playerStopBlock(player.player, false)
		health = max(0, player.player.heistRound.health - 50*FU)
	end

	if FH:setHealth(player.player, health) then
		if source
		and source.valid
		and source.type == MT_PLAYER
		and source.player
		and source.player.heistRound then
			FH:addProfit(source.player, FH.profitCVars.playerDeath.value, "Downed "..player.player.name)
		end

		return true
	else
		P_DoPlayerPain(player.player, source, inflictor) -- this is all u need for no ring thingies right? we're not gonna have flags or match emeralds

		if player.player.rings then
			local amount = min(player.player.rings, 25)

			P_PlayRinglossSound(player, player.player)
			P_PlayerRingBurst(player.player, amount)
			player.player.rings = $ - amount
		end

		return true
	end
end, MT_PLAYER)