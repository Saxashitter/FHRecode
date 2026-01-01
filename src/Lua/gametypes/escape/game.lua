local escape = _FH_ESCAPE

escape.timeLeft = 180 * TICRATE -- 3 minutes
escape.signpostThing = 501
escape.ringThing = 1

FH.ringStates.goal = {
	--- @type statenum_t
	state = S_FH_GOALRING,
	--- @type function
	spawn = function(ring, ...)
	end,
	--- @type function
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

		---@diagnostic disable-next-line: undefined-field
		if gametype.safeFinish then gametype:safeFinish() end
	end
}

function escape:init()
	FHR.escape = false
	FHR.escapeTime = 0
	FHR.signPosts = {}
	FHR.escapeRings = {}
end

function escape:load()
	for mapthing in mapthings.iterate do
		if mapthing.type == self.signpostThing then
			self:spawnSignpost(FH:getMapthingWorldPosition(mapthing))
		end
		if mapthing.type == self.ringThing then
			local x, y, z = FH:getMapthingWorldPosition(mapthing)
			local ring = FH:spawnRing(x, y, z + 96 * FU, "goal")

			ring.alpha = 0
			ring.scale = $ * 3 / 2
			table.insert(FHR.escapeRings, ring)
		end
		if mapthing.type == 402 and mapthing.mobj and mapthing.mobj.valid then
			P_RemoveMobj(mapthing.mobj)
		end
	end
end

function escape:escapeUpdate()
	if FHR.escapeTime then
		FHR.escapeTime = $ - 1

		if FHR.escapeTime == 0 then
			FH:endGame()
		end
	end
end

--- @param currentState string
function escape:update(currentState)
	if currentState ~= "game" then return end

	if FHR.escape then
		self:escapeUpdate()
	end
end

--- Starts the escape sequence.
--- @param starter player_t
function escape:startEscape(starter)
	FHR.escape = true
	FHR.escapeTime = FH:getMapVariable(nil, "fh_time", self.timeLeft) -- TODO: use cvars
	FHR.escapeStartTime = leveltime

	if starter and starter.heistRound then
		FH:addProfit(starter, FH.profitCVars.startedEscape.value, "Started the Escape Sequence")
	end

	-- make signs fly into air then disappear lol
	for _, sign in ipairs(FHR.signPosts) do
		if not sign.valid then continue end

		sign.momz = 6 * FRACUNIT
		sign.fuse = 5 * TICRATE
		sign.flags = $|MF_NOGRAVITY
		sign.state = S_SIGNSPIN1
	end

	-- ok rings you can be visible now
	for _, ring in ipairs(FHR.escapeRings) do
		if not ring.valid then continue end

		ring.alpha = FU
	end

	S_StartSoundAtVolume(nil, sfx_kc42, 70)

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
end

function escape:safeFinish()
	if not FHR.escape then
		return
	end

	local leavingCount = 0
	local totalCount = 0

	for player in players.iterate do
---@diagnostic disable-next-line: undefined-field
		if (player.heistRound and player.heistRound.spectator) or not player.mo or not player.mo.health or player.hasLeftServer then continue end

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
	local sign = P_SpawnMobj(x, y, z, MT_SIGN)
	sign.angle = angle
	
	table.insert(FHR.signPosts, sign)
end

COM_AddCommand("fh_endgame", function(player)
	FH:endGame()
end, COM_ADMIN)

COM_AddCommand("fh_startescape", function(player)
	escape:startEscape(player)
end, COM_ADMIN)