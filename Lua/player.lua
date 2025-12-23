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
--- The player's profit counter. Gained from killing enemies, collecting rings, destroying monitors, and hurting players. This would normally be what determines if they win or not.
--- @field profit fixed_t

--- Initalizes the player's round variables. Should be called once per-round.
--- @param player player_t
--- @return heistPlayerRound_t
function FH:initPlayerRound(player)
	--- @type heistPlayerRound_t
	local playerRound = {
		profit = 0
	}
	
	print("round player initalization")

	player.heistRound = playerRound
	return playerRound
end

--- Add fields to player_t
--- @class player_t
--- @field heistRound heistPlayerRound_t?
--- @field heistGlobal heistPlayerGlobal_t?

--- @param player player_t
addHook("PlayerThink", function(player)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end

	if not player.heistGlobal then
		FH:initPlayerGlobal(player)
	end
	if not player.heistRound then
		FH:initPlayerRound(player)
	end

	gametype:playerUpdate(player, FHR.currentState)
end)

addHook("ThinkFrame", function()
	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end

	for player in players.iterate do
		if not player.heistRound then return end
 
		-- TODO: make our own counter that accounts for fixed values.
		player.score = player.heistRound.profit/FU
	end
end)