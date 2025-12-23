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

--- House-keeping for rounds, per-match.
--- @class heistRoundGlobal_t

function FH:initRound()
	--- @type heistRoundGlobal_t
	local roundGlobal = {}

	FHR = roundGlobal
end

--- Add fields to player_t
--- @class player_t
--- @field heistRound heistPlayerRound_t?
--- @field heistGlobal heistPlayerGlobal_t?