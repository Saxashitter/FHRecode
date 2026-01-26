--- Global PVP manager for players.
--- Dependencies: instashield.lua, block.lua, downed.lua

local instaShieldCooldown = 35

local blockCooldown = 8
local blockDrainTics = 4 * TICRATE
local blockRegainStrengthTics = 6 * TICRATE
local blockDamage = FU / 3
local blockChargeCooldown = TICRATE

--- @class mobj_t
--- If valid, this will be how much damage the mobj does to the player in Fang's Heist.
--- @field fh_playerdamage fixed_t|nil
--- If valid, this will multiply fh_playerdamage if the player's block breaks in Fang's Heist.
--- @field fh_blockbreakmult fixed_t|nil
--- If valid, this will be how much damage the mobj does to the player's block in Fang's Heist.
--- @field fh_playerblockdamage fixed_t|nil

--- @param player player_t
function FH:playerUseBlock(player)
	FH:useBlock(player.mo)
	player.hr.blockCooldown = blockCooldown
end

--- @param player player_t
--- @param startCooldowns boolean|nil
function FH:playerStopBlock(player, startCooldowns)
	FH:stopBlock(player.mo)

	if startCooldowns == false then return end

	player.hr.blockCooldown = blockCooldown
	player.hr.blockChargeCooldown = blockChargeCooldown
end

--- @param player player_t
addHook("PlayerThink", function(player)
	local gametype = FH:isMode()

	if not gametype then return end
	if not player.hr then return end

	if FHR.currentState == "game"
	and player.mo
	and player.mo.health
	and not P_PlayerInPain(player)
	and player.cmd.buttons & BT_ATTACK > 0
	and player.lastbuttons & BT_ATTACK == 0
	and not player.hr.instaShieldCooldown
	and player.hr.canUseInstaShield
	and not player.mo.fh_block then
		FH:useInstaShield(player.mo)
		player.hr.instaShieldCooldown = instaShieldCooldown
		FH:setPlayerExpression(player, "pvp", 5 * TICRATE)
	end

	if FHR.currentState == "game"
	and player.mo
	and player.mo.health
	and not P_PlayerInPain(player)
	and player.cmd.buttons & BT_FIRENORMAL > 0
	and player.lastbuttons & BT_FIRENORMAL == 0
	and not player.hr.blockCooldown
	and player.hr.canUseBlock
	and not player.mo.fh_block
	and not player.mo.fh_instashield then
		FH:playerUseBlock(player)
	end

	if FHR.currentState == "game"
	and player.mo
	and player.mo.health
	and not P_PlayerInPain(player)
	and player.cmd.buttons & BT_FIRENORMAL == 0
	and not player.hr.blockCooldown
	and player.mo.fh_block then
		FH:playerStopBlock(player)
	end

	if player.hr.instaShieldCooldown then
		player.hr.instaShieldCooldown = $ - 1

		if not player.hr.instaShieldCooldown and player.mo then
			S_StartSoundAtVolume(player.mo, sfx_s3k41, 55)
			S_StartSoundAtVolume(player.mo, sfx_s3k44, 55)

			local ghost = P_SpawnGhostMobj(player.mo)
			ghost.fuse = 12
			ghost.destscale = 10 * FU
		end
	end

	if player.hr.blockCooldown then
		player.hr.blockCooldown = $ - 1
	end

	if not P_PlayerInPain(player)
	or not (player.mo and player.mo.health)
	or not (player.hr.lastHitBy and player.hr.lastHitBy.valid) then
		player.hr.lastHitBy = nil
	end

	if player.mo then
		if player.mo.fh_block then
			local t = FixedDiv(player.hr.blockStrength, player.hr.blockMaxStrength)
			local scale = ease.linear(t, player.mo.scale / 2, player.mo.scale * 3 / 2)
			local block = player.mo.fh_block

			block.scale = scale

			---@diagnostic disable-next-line: assign-type-mismatch
			if player.hr.blockStrength > blockDamage
			and player.hr.blockStrength - FU / blockDrainTics <= blockDamage then
				-- hey, if you get hit, you are FUCKED
				S_StartSoundAtVolume(player.mo, sfx_s258, 100)
			end
			---@diagnostic disable-next-line: assign-type-mismatch
			player.hr.blockStrength = max(0, $ - FU / blockDrainTics)

		elseif player.hr.blockChargeCooldown then
			player.hr.blockChargeCooldown = $ - 1

			if player.hr.blockChargeCooldown == 0 then
				S_StartSound(player.mo, sfx_3db16)
			end

		elseif player.hr.blockStrength < player.hr.blockMaxStrength then
			---@diagnostic disable-next-line: assign-type-mismatch
			player.hr.blockStrength = min(player.hr.blockMaxStrength, $ + FU / blockRegainStrengthTics)

			if player.hr.blockStrength == player.hr.blockMaxStrength then
				S_StartSound(player.mo, sfx_3db06)
			end
		end
	end
end)

addHook("JumpSpecial", function(player)
	if not FH:isMode() then return end
	if not player.hr then return end
	if not player.mo then return end
	if player.hr.downed then
		return true
	end
end)

addHook("SpinSpecial", function(player)
	if not FH:isMode() then return end
	if not player.hr then return end
	if not player.mo then return end
	if player.hr.downed then
		return true
	end
end)

--- @param targ mobj_t
--- @param inf mobj_t
--- @param source mobj_t
addHook("ShouldDamage", function(targ, inf, source)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end

	if FHR.currentState ~= "game" then return false end

	-- TODO: friendlyfire checks from the gamemode and the cvar
	-- UPD: teaming added so this is easy
	if source and source.valid and source.type == MT_PLAYER and source.player and source.player.hr then
		if not targ.player then return end
		if not targ.player.hr then return end
		if FH:isInTeam(targ.player, source.player) then
			if CV_FindVar("friendlyfire").value == 0 then
				return false
			end
		end
		if targ.player.powers[pw_flashing] then return false end
		if targ.player.powers[pw_invulnerability] then return false end
		if targ.player.powers[pw_super] then return false end
		if targ.player.powers[pw_strong] & STR_GUARD then return false end
		if targ.player.hr.downed then return false end

		return true
	end

	if targ.fh_instashield then
		return false
	end
end, MT_PLAYER)

---@param victim mobj_t
---@param inflictor mobj_t
---@param source mobj_t
---@param damagetype integer
addHook("MobjDamage", function(victim, inflictor, source, _, damagetype)
	if not FH:isMode() then return end
	if not victim.player then return end
	if not victim.player.hr then return end

	if victim.player.powers[pw_invulnerability] then return end
	if victim.player.powers[pw_super] then return end

	local gametype = FH:isMode()
	local damage = 18 * FU

	if inflictor and inflictor.valid and inflictor.fh_playerdamage ~= nil then
		damage = inflictor.fh_playerdamage
	end 

	if (damagetype & DMG_DEATHMASK) then
		return
	elseif victim.fh_block then
		--- TODO: slap this in a function
		--- @diagnostic disable-next-line: assign-type-mismatch
		local blockDamage = blockDamage

		if inflictor and inflictor.valid and inflictor.fh_playerblockdamage ~= nil then
			blockDamage = inflictor.fh_playerblockdamage
		end

		victim.player.hr.blockStrength = max(0, $ - blockDamage)

		if victim.player.hr.blockStrength <= blockDamage then
			S_StartSoundAtVolume(victim, sfx_s258, 100)
		end

		local overlay = P_SpawnMobjFromMobj(victim, 0,0,0, MT_FH_OVERLAY) --[[@as heistOverlay_t]]
		overlay.target = victim
		overlay.translation = "FH_AllRed"
		overlay.alphaFuse = 15

		if victim.player.hr.blockStrength > 0 then
			victim.player.powers[pw_flashing] = 16
			S_StartSoundAtVolume(victim, sfx_kc40, 60)

			if inflictor and inflictor.valid and inflictor.health and inflictor.flags & MF_MISSILE then
				inflictor.target = victim
				FH:knockbackMobj(inflictor, victim)
			end

			return true
		end

		FH:playerStopBlock(victim.player, false)

		if inflictor and inflictor.valid and inflictor.fh_blockbreakmult ~= nil then
			damage = FixedMul($, inflictor.fh_blockbreakmult)
		end
	end

	if victim.player.powers[pw_flashing] then return end
	if victim.player.powers[pw_shield] then return end

	local overlay = P_SpawnMobjFromMobj(victim, 0,0,0, MT_FH_OVERLAY) --[[@as heistOverlay_t]]
	overlay.target = victim
	overlay.translation = "FH_AllRed"
	overlay.alphaFuse = 15

	if FH:setHealth(victim.player, max(0, victim.player.hr.health - damage)) then
		if source
		and source.valid
		and source.type == MT_PLAYER
		and source.player
		and source.player.hr then
			FH:addProfit(source.player, FH.profitCVars.playerDeath.value, "Downed "..victim.player.name)
		end

		if not gametype.killOnDowned then
			FH:addProfit(victim.player, -FH.profitCVars.playerDeath.value, "Got downed")
		end
		return true
	else
		if source
		and source.valid
		and source.type == MT_PLAYER
		and source.player
		and source.player.hr
		and gametype.damageAwardsPlayers then
			FH:addProfit(source.player, FH.profitCVars.playerHurt.value, "Damaged "..victim.player.name)
		end

		-- TODO: unhardcode

		if gametype.damageAwardsPlayers then
			FH:addProfit(victim.player, -FH.profitCVars.playerHurt.value, "Got hurt")
		end
		FH:setPlayerExpression(victim.player, "hurt", 2 * TICRATE)
		P_DoPlayerPain(victim.player, source, inflictor)

		if victim.player.rings then
			local amount = min(victim.player.rings, 25)

			P_PlayerRingBurst(victim.player, amount)
			S_StartSound(victim, sfx_altow1)
			victim.player.rings = $ - amount
		end

		for k, v in ipairs(FHR.modifiers) do
			local modifier = FH.modifiers.all[v] --[[@as heistModifier_t]]
	
			modifier:playerDamage(victim.player, inflictor, source)
		end

		return true
	end
end, MT_PLAYER)

addHook("MobjDeath", function(victim, _, source, _, damagetype)
	if not FH:isMode() then return end
	if not victim.player then return end
	if not victim.player.hr then return end

	local player = victim.player

	if player.hr and player.hr.lastHitBy and not source then
		source = player.hr.lastHitBy
	end

	if source
	and source.valid
	and source.type == MT_PLAYER
	and source.player
	and source.player.hr
	and not source.player.hr.spectator then
		FH:addProfit(source.player, FH.profitCVars.playerDeath.value, "Killed "..victim.player.name)
	end
	
	FH:addProfit(player, -FH.profitCVars.playerDeath.value, "Killed")

	for i = #player.hr.collectibles, 1, -1 do
		FH:dropCollectible(player, player.hr.collectibles[i])
	end
	FH:playerStopBlock(player, false)
	player.hr.health = FH.characterHealths[victim.skin] or 100*FU
end, MT_PLAYER)

addHook("PlayerQuit", function(player)
	if not FH:isMode() then return end
	if not player.hr then return end

	for i = #player.hr.collectibles, 1, -1 do
		FH:dropCollectible(player, player.hr.collectibles[i])
	end

	if player.mo and player.mo.valid then
		FH:playerStopBlock(player, false)
	end
end, MT_PLAYER)