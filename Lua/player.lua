--- House-keeping for players globally.
--- @class heistPlayerGlobal_t

--- Initalizes the player's global variables. Should be called once per player initalization.
--- @param player player_t
--- @return heistPlayerGlobal_t
function FH:initPlayerGlobal(player)
	--- @type heistPlayerGlobal_t
	local playerGlobal = {}

	print("global player initalization")
	
	player.heistGlobal = playerGlobal
	return playerGlobal
end

--- House-keeping for players per-round.
--- @class heistPlayerRound_t

--- Initalizes the player's round variables. Should be called once per-round.
--- @param player player_t
--- @return heistPlayerRound_t
function FH:initPlayerRound(player)
	--- @type heistPlayerRound_t
	local playerRound = {}
	
	print("round player initalization")

	player.heistRound = playerRound
	return playerRound
end

--- Add fields to player_t
--- @class player_t
--- @field heistRound heistPlayerRound_t?
--- @field heistGlobal heistPlayerGlobal_t?

--- Checks if the player is in a exit sector. Mainly used to start the escape sequence in Escape modes.
--- @param player player_t
function FH:isPlayerInExitSector(player)
	if player.mo.subsector.sector.specialflags & SSF_EXIT > 0 then
		return true
	end

	for fof in player.mo.subsector.sector.ffloors() do
		if player.mo.z < fof.bottomheight then continue end
		if player.mo.z+player.mo.height > fof.topheight then continue end
		if fof.sector.specialflags & SSF_EXIT == 0 then continue end

		return true
	end

	return false
end

--- @param player player_t
addHook("PlayerThink", function(player)
	if not player.heistGlobal then
		FH:initPlayerGlobal(player)
	end
	if not player.heistRound then
		FH:initPlayerRound(player)
	end
end)
