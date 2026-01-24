local escape = _FH_ESCAPE

escape.signpostThing = 501
escape.ringThing = 1
escape.timesUpStart = 22591 * TICRATE / MUSICRATE
escape.timeLeft = 180 -- 3 minutes

local tickSounds = {}
for i = 0, 9 do
	--- @type soundnum_t
	local sound = freeslot("sfx_fh_tc"..i)
	sfxinfo[sound].caption = i > 0 and "Tick..." or 'Uh oh.'

	tickSounds[i] = sound
end
tickSounds[10] = tickSounds[9]

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
		if player.hr.escaped then return end

		player.hr.forcedPosition = {
			x = ring.x,
			y = ring.y,
			z = ring.z,
			angle = player.drawangle
		}
		player.hr.stasis = true
		player.hr.escaped = true
		player.hr.qualified = true
		player.powers[pw_flashing] = 2 * TICRATE + 1 -- infinite invulnerability!!
		player.mo.alpha = 0

		for _, v in ipairs(player.hr.collectibles) do
			if v and v.valid then
				v.target = nil
				P_RemoveMobj(v)
			end
		end
		player.hr.collectibles = {}

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
		if player.hr.escaped then return end

		-- find other link
		local otherRing = FHR.round2FinishRings[ring.index]

		if not otherRing and otherRing.valid then
			return
		end

		local speed = FH:pointTo3DDist(0,0,0, player.mo.momx, player.mo.momy, player.mo.momz)

		P_SetOrigin(player.mo, otherRing.x, otherRing.y, otherRing.z)
		P_InstaThrust(player.mo, otherRing.angle, speed)

		if FHN.globalMusic == "FH_ESC" then
			FH:changePlayerMusic(player, "FH_RN2", true)
		end

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
	FHR.appendedSideModifiers = {}

	FHR.timesUpStart = self.timesUpStart
	FHR.timesUpMusic = "FH_OVT"
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

		if FHR.escapeTime == 2 * TICRATE + FHR.timesUpStart then
			S_FadeMusic(0, 2 * MUSICRATE)
		end

		if FHR.escapeTime <= #tickSounds * TICRATE and FHR.escapeTime % TICRATE == 0 then
			local sound = tickSounds[FHR.escapeTime / TICRATE]
			local quake = FHR.escapeTime == 0 and 26 * FU or 8 * FU
			local duration = FHR.escapeTime == 0 and -1 or 16

			S_StartSound(nil, sound)
			P_StartQuake(quake, duration)
		end

		-- TODO: separate alot of these into their own functions

		if FHR.escapeTime == FHR.timesUpStart then
			FH:changeMusic(FHR.timesUpMusic, true)

			P_SetupLevelSky(56)
			P_SwitchWeather(54)
			for player in players.iterate do
				P_SetSkyboxMobj(nil, player)

				if player.hr then
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

				if player.hr then
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

	if starter and starter.hr then
		FH:addProfit(starter, FH.profitCVars.startedEscape.value, "Started the Escape Sequence", 0)
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
		local used = {}

		-- Total modifiers scale with retakes
		local totalMods = max(1, FHN.retakes)
		local sideCount = max(0, totalMods - 1)
		local mainModifier

		if FHR.appendedMainModifier then
			mainModifier = FH:getModifier(FHR.appendedMainModifier)
		else
			mainModifier = FH:randomItems(FH.modifiers.types.main, 1)[1]
		end

		if mainModifier then
			used[mainModifier.id] = true
			FH:activateModifier(mainModifier)

			if mainModifier.timesUpMusic ~= nil then
				FHR.timesUpMusic = mainModifier.timesUpMusic
			end
			if mainModifier.timesUpStart ~= nil then
				FHR.timesUpStart = mainModifier.timesUpStart
			end
		end

		local sideModifiers = {}

		-- Consume appended side modifiers first
		for _, id in ipairs(FHR.appendedSideModifiers) do
			if #sideModifiers >= sideCount then break end

			local mod = FH:getModifier(id)
			if mod and not used[mod.id] then
				table.insert(sideModifiers, mod)
				used[mod.id] = true
			end
		end

		-- Fill remaining slots randomly
		if #sideModifiers < sideCount then
			local pool = {}

			for _, mod in ipairs(FH.modifiers.types.side) do
				if not used[mod.id] then
					table.insert(pool, mod)
				end
			end

			local needed = min(sideCount - #sideModifiers, #pool)
			local picks = FH:randomItems(pool, needed)

			for _, mod in ipairs(picks) do
				table.insert(sideModifiers, mod)
				used[mod.id] = true
			end
		end

		-- Activate side modifiers
		for _, mod in ipairs(sideModifiers) do
			FH:activateModifier(mod)
		end

		-- decide on retake song based on map
		escapeSong = FH:getMapVariable(nil, "fh_retake1theme", "FH_RTK")
	
		for i = 2, FHN.retakes do
			escapeSong = $ or FH:getMapVariable(nil, "fh_retake"..i.."theme")
		end

		if mainModifier and mainModifier.music then
			escapeSong = mainModifier.music
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
		if not player.hr then continue end

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
		-- if (player.hr and player.hr.spectator) or not player.mo or not player.mo.health or player.hasLeftServer then continue end
		if not player.hr then continue end
		if player.hr.spectator then continue end
		if player.hr.downed then continue end
		if not player.mo then continue end
		if not player.mo.health then continue end
		if player.hasLeftServer then continue end

		totalCount = $ + 1

		if player.hr.escaped then
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

COM_AddCommand("fh_appendmodifier", function(player, id)
	local mod = FH:getModifier(id)

	if not mod then
		CONS_Printf(player, "Unknown modifier: "..id)
		return
	end

	if mod.type == "main" then
		FHR.appendedMainModifier = id
		CONS_Printf(player, "Appended MAIN modifier: "..id)
		return
	end

	if mod.type == "side" then
		for _, v in ipairs(FHR.appendedSideModifiers) do
			if v == id then
				CONS_Printf(player, "Side modifier already appended.")
				return
			end
		end

		table.insert(FHR.appendedSideModifiers, id)
		CONS_Printf(player, "Appended SIDE modifier: "..id)
		return
	end

	CONS_Printf(player, "Modifier type not appendable.")
end)



COM_AddCommand("fh_setretakes", function(player, amount)
	amount = tonumber(amount)
	if amount == nil then return end

	FHN.retakes = amount
end, COM_ADMIN)