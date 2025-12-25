--- House-keeping for players globally.
--- @class heistPlayerGlobal_t
--- The sidemove of the player, in case Fang's Heist resets cmd.sidemove. Useful for menus.
--- @field sidemove SINT8
--- The forwardmove of the player, in case Fang's Heist resets cmd.sidemove. Useful for menus.
--- @field forwardmove SINT8
--- The currently pressed buttons for the player, in case Fang's Heist resets cmd.sidemove. Useful for menus.
--- @field buttons UINT16
--- The last sidemove of the player. Useful for menus.
--- @field lastSidemove SINT8
--- The last forwardmove of the player. Useful for menus.
--- @field lastForwardmove SINT8
--- The last pressed buttons for the player. Useful for menus.
--- @field lastButtons UINT16
--- The player's current skin. The player is locked to this skin at all times, but the player is able to change this within Pre-Game.
--- @field skin number

--- Initalizes the player's global variables. Should be called once per player initalization.
--- @param player player_t
--- @return heistPlayerGlobal_t
function FH:initPlayerGlobal(player)
	--- @type heistPlayerGlobal_t
	local playerGlobal = {
		sidemove = player.cmd.sidemove,
		forwardmove = player.cmd.forwardmove,
		buttons = player.cmd.buttons,
		lastSidemove = player.cmd.sidemove,
		lastForwardmove = player.cmd.forwardmove,
		lastButtons = player.cmd.buttons,
		skin = 0,
	}

	print("global player initalization")
	
	player.heistGlobal = playerGlobal
	return playerGlobal
end

--- House-keeping for players per-round.
--- @class heistPlayerRound_t
--- The player's profit counter. Gained from killing enemies, collecting rings, destroying monitors, and hurting players. This would normally be what determines if they win or not.
--- @field profit fixed_t
--- If this is set to a table containing x, y, z and angle positions. The player will forcefully teleport here and be unable to move until' this is set to false.
--- @field forcedPosition table?
--- Set this to true to stop the player from pressing any inputs whatsoever. This should be used over PF_STASIS due to it resetting ALL the player's buttons, as well as ensuring compatibility with menus.
--- @field stasis boolean

--- Initalizes the player's round variables. Should be called once per-round.
--- @param player player_t
--- @return heistPlayerRound_t
function FH:initPlayerRound(player)
	local gametype = FH:isMode()

	--- @type heistPlayerRound_t
	local playerRound = {
		profit = 0,
		stasis = false
	}
	
	print("round player initalization")

	player.heistRound = playerRound
	gametype:playerInit(player)

	return playerRound
end

--- Add fields to player_t
--- @class player_t
--- @field heistRound heistPlayerRound_t?
--- @field heistGlobal heistPlayerGlobal_t?

--- @param player player_t
--- @param gametype heistGametype_t
local function initChecks(player, gametype)
	if not player.heistGlobal then
		FH:initPlayerGlobal(player)
	end
	if not player.heistRound then
		FH:initPlayerRound(player)
	end
end

addHook("PreThinkFrame", function()
	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end

	for player in players.iterate do
		initChecks(player, gametype)

		player.heistRound.lastSidemove = player.heistRound.sidemove
		player.heistRound.lastForwardmove = player.heistRound.forwardmove
		player.heistRound.lastButtons = player.heistRound.buttons

		player.heistRound.sidemove = player.cmd.sidemove
		player.heistRound.forwardmove = player.cmd.forwardmove
		player.heistRound.buttons = player.cmd.buttons

		if player.heistRound.stasis then
			player.cmd.sidemove = 0
			player.cmd.forwardmove = 0
			player.cmd.buttons = 0
			player.lastbuttons = 0
		end
	end
end)

--- @param player player_t
addHook("PlayerThink", function(player)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end

	initChecks(player, gametype)

	if player.heistRound.forcedPosition and player.mo and player.mo.health then
		P_SetOrigin(player.mo,
			player.heistRound.forcedPosition.x,
			player.heistRound.forcedPosition.y,
			player.heistRound.forcedPosition.z
		)
		player.drawangle = player.heistRound.forcedPosition.angle
		player.mo.momx = 0
		player.mo.momy = 0
		player.mo.momz = 0
		player.mo.state = S_PLAY_STND
		player.mo.frame = ($ & ~FF_FRAMEMASK)|A
		player.mo.tics = -1
	end

	local state = FH.gamestates[FHR.currentState]

	gametype:playerUpdate(player, FHR.currentState)
	state:playerUpdate(player)
end)

--- @param player player_t
addHook("PlayerQuit", function(player)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end

	initChecks(player, gametype)

	gametype:playerQuit(player, FHR.currentState)
end)

--- @param target mobj_t
addHook("MobjDeath", function(target)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end
	if not target.player then return end

	initChecks(target.player, gametype)

	gametype:playerDeath(target.player, FHR.currentState)
end, MT_PLAYER)

addHook("ThinkFrame", function()
	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end

	for player in players.iterate do
		initChecks(player, gametype)
 
		-- TODO: make our own counter that accounts for fixed values.
		player.score = player.heistRound.profit/FU
	end
end)