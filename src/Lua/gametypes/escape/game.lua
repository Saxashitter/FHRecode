local escape = _FH_ESCAPE

escape.signpostThing = 501
escape.ringThing = 1
escape.timesUpStart = 22591 * TICRATE / MUSICRATE
escape.timeLeft = 180 -- 3 minutes

freeslot("S_FH_ROUND2RING") 

states[S_FH_ROUND2RING].sprite = freeslot("SPR_R2RI")
states[S_FH_ROUND2RING].tics = -1
states[S_FH_ROUND2RING].frame = FF_ANIMATE
states[S_FH_ROUND2RING].var1 = F
states[S_FH_ROUND2RING].var2 = 2

sfxinfo[freeslot("sfx_fh_tck")].caption = "Click..."
sfxinfo[freeslot("sfx_fh_ovr")].caption = "Uh oh."
sfxinfo[freeslot("sfx_fh_gog")].caption = "G-G-G-GO! GO! GO!"

FH.ringStates["Goal"] = {
	--- @type statenum_t
	state = S_FH_GOALRING,
	--- @type function
	spawn = function(ring)
		ring.alpha = 0
		ring.scale = $ * 3 / 2
		table.insert(FHR.escapeRings, ring)
	end,
	--- @type function
	--- @param ring mobj_t
	--- @param player player_t
	touch = function(ring, player)
		local gametype = FH:isMode()
		if not gametype then return end -- just here for formatting purposes

		if not FHR.escape then return end
		if player.heistRound.escaped then return end

		player.heistRound.forcedPosition = {
			x = ring.x,
			y = ring.y,
			z = ring.z,
			angle = player.drawangle
		}
		player.heistRound.stasis = true
		player.heistRound.escaped = true
		player.powers[pw_flashing] = 2 * TICRATE + 1 -- infinite invulnerability!!
		player.mo.alpha = 0

		for _, v in ipairs(player.heistRound.collectibles) do
			if v and v.valid then
				v.target = nil
				P_RemoveMobj(v)
			end
		end
		player.heistRound.collectibles = {}

		S_StartSound(player.mo, sfx_s1c3)
		S_StartSound(ring, sfx_s1c3)

		---@diagnostic disable-next-line: undefined-field
		if gametype.safeFinish then gametype:safeFinish() end
	end
}

FH.ringStates["Round 2 Teleport From"] = {
	--- @type statenum_t
	state = S_FH_ROUND2RING,
	--- @type function
	spawn = function(ring)
		ring.alpha = FU
		ring.scale = $ * 3 / 2
		ring.index = (ring.spawnpoint.args[0] or 0) + 1
		FHR.round2StartRings[ring.index] = ring
	end,
	--- @type function
	touch = function(ring, player)
		local gametype = FH:isMode()
		if not gametype then return end -- just here for formatting purposes

		if not FHR.escape then return end
		if player.heistRound.escaped then return end

		-- find other link
		local otherRing = FHR.round2FinishRings[ring.index]

		if not otherRing and otherRing.valid then
			return
		end
	
		local speed = R_PointToDist2(0, 0, R_PointToDist2(0, 0, player.mo.momx, player.mo.momy), player.mo.momz)

		P_SetOrigin(player.mo, otherRing.x, otherRing.y, otherRing.z)
		P_InstaThrust(player.mo, otherRing.angle, speed)
	
		S_StartSound(player.mo, sfx_s1c3)
		S_StartSound(ring, sfx_s1c3)
		S_StartSound(otherRing, sfx_s1c3)
	
		player.mo.angle = otherRing.angle
	end
}

FH.ringStates["Round 2 Teleport To"] = {
	--- @type statenum_t
	state = S_FH_ROUND2RING,
	--- @type function
	spawn = function(ring)
		ring.alpha = FU
		ring.scale = $ * 3 / 2
		ring.index = (ring.spawnpoint.args[0] or 0) + 1
		FHR.round2FinishRings[ring.index] = ring

	end,
	touch = function() end
}

function escape:init()
	FHR.escape = false
	FHR.escapeTime = 0
	FHR.maxEscapeTime = 0
	FHR.signPosts = {}
	FHR.escapeRings = {}
	FHR.round2StartRings = {}
	FHR.round2FinishRings = {}
	FHR.endPosition = {x = 0, y = 0, z = 0, angle = 0}
	FHR.enemyRespawnQueue = {}
end

function escape:load()
	for mapthing in mapthings.iterate do
		if mapthing.type == self.signpostThing then
			self:spawnSignpost(FH:getMapthingWorldPosition(mapthing))
		end
		if mapthing.type == 402 and mapthing.mobj and mapthing.mobj.valid then
			P_RemoveMobj(mapthing.mobj)
		end
	end
end

function escape:escapeUpdate()
	if FHR.escapeTime then
		FHR.escapeTime = $ - 1

		if FHR.escapeTime == 2 * TICRATE + self.timesUpStart then
			S_FadeMusic(0, 2 * MUSICRATE)
		end

		if FHR.escapeTime <= 10 * TICRATE and FHR.escapeTime % TICRATE == 0 then
			local sound = FHR.escapeTime == 0 and sfx_fh_ovr or sfx_fh_tck
			local quake = FHR.escapeTime == 0 and 26 * FU or 8 * FU
			local duration = FHR.escapeTime == 0 and -1 or 16

			S_StartSound(nil, sound)
			P_StartQuake(quake, duration)
		end

		if FHR.escapeTime == self.timesUpStart then
			FH:changeMusic("FH_OVT", true)
			
			P_SetupLevelSky(56)
			P_SwitchWeather(54)
			for player in players.iterate do
				P_SetSkyboxMobj(nil, player)
				P_FlashPal(player, 0, 10)

				if player.heistRound then
					FH:setPlayerExpression(player, "hurt")
				end
			end
		end
		
		if FHR.escapeTime == 0 then
			print("Eggman has spawned! RUN!!")
			P_SpawnMobj(FHR.endPosition.x, FHR.endPosition.y, FHR.endPosition.z, MT_FH_EGGMAN_TIMESUP)
			
			P_SwitchWeather(1)
			P_SetupLevelSky(57)
			for player in players.iterate do
				P_SetSkyboxMobj(nil, player)
				P_FlashPal(player, 0, 10)

				if player.heistRound then
					FH:setPlayerExpression(player, "dead")
				end
			end
		end
	end
end

--- @param currentState string
function escape:update(currentState)
	if currentState ~= "game" then return end

	for i = #FHR.enemyRespawnQueue, 1, -1 do
		local data = FHR.enemyRespawnQueue[i]

		if data.time then
			data.time = $ - 1
			continue
		end

		local x, y, z, angle = FH:getMapthingWorldPosition(data.mapthing)

		local enemy = P_SpawnMobj(x, y, z, data.type)
		if enemy and enemy.valid then
			enemy.angle = angle
			enemy.spawnpoint = data.mapthing
			data.mapthing.mobj = enemy
		end

		table.remove(FHR.enemyRespawnQueue, i)
	end

	if FHR.escape then
		self:escapeUpdate()
	end
end

--- Starts the escape sequence.
--- @param starter player_t
function escape:startEscape(starter)
	FHR.escape = true
	FHR.escapeTime = FH:getMapVariable(nil, "fh_escapetime", self.timeLeft) * TICRATE -- TODO: use cvars
	FHR.maxEscapeTime = FHR.escapeTime
	FHR.escapeStartTime = leveltime

	if starter and starter.heistRound then
		FH:addProfit(starter, FH.profitCVars.startedEscape.value, "Started the Escape Sequence")
	end

	-- make signs fly into air then disappear lol
	for _, sign in ipairs(FHR.signPosts) do
		if not sign.valid then continue end

		sign.momz = 6 * FRACUNIT
		sign.fuse = 5 * TICRATE
		sign.flags = $|MF_NOGRAVITY|MF_NOCLIPHEIGHT
		sign.state = S_SIGNSPIN1
	end

	-- ok rings you can be visible now
	for _, ring in ipairs(FHR.escapeRings) do
		if not ring.valid then continue end

		ring.alpha = FU
	end

	S_StartSoundAtVolume(nil, sfx_kc42, 70)
	S_StartSound(nil, sfx_fh_gog)

	print(starter.name.." started the escape sequence!")

	local escapeSong = FH:getMapVariable(nil, "fh_escapetheme", "FH_ESC")

	if FHN.retakes then
		-- activate modifiers
		local mainModifier = FH:randomItems(FH.modifiers.types.main, 1)[1]
		local sideModifiers = {}

		if FHN.retakes > 1 then
			sideModifiers = FH:randomItems(FH.modifiers.types.side, FHN.retakes - 1)
		end

		FH:activateModifier(mainModifier)
		for k, v in ipairs(sideModifiers) do
			FH:activateModifier(v)
		end

		-- decide on retake song based on map
		escapeSong = FH:getMapVariable(nil, "fh_retake1theme", "FH_RTK")
		for i = 2, FHN.retakes do
			escapeSong = $ or FH:getMapVariable(nil, "fh_retake"..i.."theme")
		end
	end

	FH:changeMusic(escapeSong)

	local linedef = FH:getMapVariable(nil, "fh_escapelinedeftrigger", nil)

	if linedef ~= nil then
		--- @type mobj_t|nil
		local mo = starter.mo

		if not starter.mo or not starter.mo.valid then
			mo = nil
		end
	
		P_LinedefExecute(linedef, mo)
	end

	for player in players.iterate do
		if not player.heistRound then continue end

		FH:setPlayerExpression(player, "hurt", 5 * TICRATE)
	end
end

function escape:safeFinish()
	if not FHR.escape then
		return
	end

	local leavingCount = 0
	local totalCount = 0

	for player in players.iterate do
		---@diagnostic disable-next-line: undefined-field
		-- if (player.heistRound and player.heistRound.spectator) or not player.mo or not player.mo.health or player.hasLeftServer then continue end
		if not player.heistRound then continue end
		if player.heistRound.spectator then continue end
		if player.heistRound.downed then continue end
		if not player.mo then continue end
		if not player.mo.health then continue end
		if player.hasLeftServer then continue end

		totalCount = $ + 1

		if player.heistRound.escaped then
			leavingCount = $ + 1
		end
	end

	if leavingCount >= totalCount then
		FH:endGame()
		return
	end
end

--- Spawn the signpost at the given coordinates.
--- @param x fixed_t
--- @param y fixed_t
--- @param z fixed_t
--- @param angle angle_t
function escape:spawnSignpost(x, y, z, angle)
	FHR.endPosition = {
		x = x,
		y = y,
		z = z
	}

	local sign = P_SpawnMobj(x, y, z, MT_SIGN)
	sign.angle = angle
	
	table.insert(FHR.signPosts, sign)
end

--- @param target mobj_t
addHook("MobjDeath", function(target)
	if not FH:isMode() then return end
	if not target.valid then return end
	if target.flags & MF_ENEMY == 0 then return end
	if not target.spawnpoint then return end

	-- queue enemy for respawn
	table.insert(FHR.enemyRespawnQueue, {
		mapthing = target.spawnpoint,
		type = target.type,
		time = 30 * TICRATE
	})
end)

COM_AddCommand("fh_startescape", function(player)
	escape:startEscape(player)
end, COM_ADMIN)

COM_AddCommand("fh_setretakes", function(player, amount)
	amount = tonumber(amount)
	if amount == nil then return end

	FHN.retakes = amount
end, COM_ADMIN)