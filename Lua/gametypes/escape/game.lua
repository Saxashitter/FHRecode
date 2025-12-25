local escape = _FH_ESCAPE

escape.timeLeft = 120 * TICRATE -- 2 minutes
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

		if not FHN.escape then return end
		if player.heistRound.escaped then return end

		player.heistRound.forcedPosition = {
			x = ring.x,
			y = ring.y,
			z = ring.z,
			angle = player.drawangle
		}
		player.heistRound.escaped = true
		player.mo.alpha = 0

		---@diagnostic disable-next-line: undefined-field
		if gametype.safeFinish then gametype:safeFinish() end
	end
}

function escape:init()
	FHN.escape = false
	FHN.escapeTime = 0
	FHN.signPosts = {}
	print("Started.")
end

function escape:load()
	for mapthing in mapthings.iterate do
		if mapthing.type == self.signpostThing then
			self:spawnSignpost(FH:getMapthingWorldPosition(mapthing))
		end
		if mapthing.type == self.ringThing then
			local x, y, z = FH:getMapthingWorldPosition(mapthing)
			local ring = FH:spawnRing(x, y, z + 128 * FU, "goal")

			ring.scale = $ * 3 / 2
		end
	end
end

function escape:escapeUpdate()
	if FHN.escapeTime then
		FHN.escapeTime = $ - 1

		if FHN.escapeTime % TICRATE == 0 then
			print("Tick... "..FHN.escapeTime / TICRATE)
		end
	end
end

--- @param currentState string
function escape:update(currentState)
	if currentState ~= "game" then return end

	if FHN.escape then
		self:escapeUpdate()
	end
end

--- Starts the escape sequence.
--- @param starter player_t
function escape:startEscape(starter)
	FHN.escape = true
	FHN.escapeTime = escape.timeLeft -- TODO: use cvars

	-- make signs fly into air then disappear lol
	for _, sign in ipairs(FHN.signPosts) do
		sign.momz = 4 * FRACUNIT
		sign.fuse = 5 * TICRATE
		sign.flags = $|MF_NOGRAVITY
		sign.state = S_SIGNSPIN1
	end

	print(starter.name.." started the escape sequence!")

	FH:changeMusic("FH_ESC")
end

function escape:safeFinish()
	print("Running game-ending check.")
	local leavingCount = 0
	local totalCount = 0

	for player in players.iterate do
		if player.spectator or not player.mo or not player.mo.health then continue end

		totalCount = $ + 1

		if player.heistRound.escaped then
			leavingCount = $ + 1
		end
	end

	if leavingCount >= totalCount then
		print("GAME OVER!!")
		FH:endGame()
		return
	end

	print("Game not over...")
end

--- Spawn the signpost at the given coordinates.
--- @param x fixed_t
--- @param y fixed_t
--- @param z fixed_t
--- @param angle angle_t
function escape:spawnSignpost(x, y, z, angle)
	local sign = P_SpawnMobj(x, y, z, MT_SIGN)
	sign.angle = angle
	
	table.insert(FHN.signPosts, sign)

	print("Signpost #"..#FHN.signPosts.." spawned at: ")
	print("    X: "..x/FU)
	print("    Y: "..y/FU)
	print("    Z: "..z/FU)
	print("    ANGLE: "..AngleFixed(angle)/FU)
end

COM_AddCommand("fh_endgame", function(player)
	FH:endGame()
end)