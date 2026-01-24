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
--- If this is true, the player will be in spectator mode when the round starts.
--- @field spectatorMode boolean
--- The team that this player is on.
--- @field team heistTeam_t

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
		spectatorMode = false,
		team = {
			players = {player}
		}
	}
	
	player.hg = playerGlobal
	return playerGlobal
end

--- House-keeping for players per-round.
--- @class heistPlayerRound_t
--- The player's profit counter. Gained from killing enemies, collecting rings, destroying monitors, and hurting players. This would normally be what determines if they win or not.
--- @field profit fixed_t
--- Tics until' the Insta-Shield can be used again for the player.
--- @field instaShieldCooldown tic_t
--- If this is set to a table containing x, y, z and angle positions. The player will forcefully teleport here and be unable to move until' this is set to false.
--- @field forcedPosition table?
--- Set this to true to stop the player from pressing any inputs whatsoever. This should be used over PF_STASIS due to it resetting ALL the player's buttons, as well as ensuring compatibility with menus.
--- @field stasis boolean
--- Used during Pre-Game for animations in the UI.
--- @field selectedSkinTime tic_t
--- Decides the current state of the menu for Pre-Game.
--- @field pregameState string
--- The last skin the player had enabled before switching. It's only purpose is for the Pre-Game UI.
--- @field lastSkin INT32|nil
--- The last direction the player switched characters towards. It's only purpose is for the Pre-Game UI. Either -1 or 1.
--- @field lastSwap integer|nil
--- If this is true, the player is determined as downed. They will be forced into a crawling state, and can barely do anything. They will be revived once downedTime hits 0.
--- @field downed boolean
--- Set the timer for the player to be downed in tics. If set to 0, then the timer won't be active.
--- @field downedTime tic_t
--- Set this to false if you don't want the player to use the insta-shield. Defaults to true.
--- @field canUseInstaShield boolean
--- Set this to false if you don't want the player to use the block. Defaults to true.
--- @field canUseBlock boolean
--- The block's max strength it can reach to.
--- @field blockMaxStrength fixed_t
--- The block's current strength.
--- @field blockStrength fixed_t
--- The cooldown until' the block can start recharging.
--- @field blockChargeCooldown tic_t
--- The cooldown until' the player can use the block again.
--- @field blockCooldown tic_t
--- If the player is spectator, this will be true. Used instead of player.spectator due to the chance that the player somehow stops being a spectator.
--- @field spectator boolean
--- The player's current health.
--- @field health fixed_t
--- If this is set to a number, the player will be forced to that skin.
--- @field skin number|nil
--- The player's current map selected within the map vote. Defaults to 2 (in the middle)
--- @field mapSelection integer
--- If this is true, the player has selected a map in the map vote.
--- @field mapVote boolean
--- The current amount of collectibles the player has on their head.
--- @field collectibles table<heistCollectible_t>
--- Logs how the player gains Profit, for use within intermission.
--- @field profitLog table<table>
--- The last time the player gained profit, used for UI.
--- @field profitUI table
--- The current selected option for the Fang's Heist menu state within Pre-game.
--- @field pregameMenuSelection integer
--- How far down should the "camera" in the menu state be?
--- @field pregameMenuLerp fixed_t
--- The path for the player's current submenu with the Pre-game Menu state.
--- @field pregameMenuPath table
--- The player's current expression on the hud. Defaults to ""
--- @field expression string
--- The player's last expression. If expressionTics is valid, then this will be the expression the player goes to after it hits 0.
--- @field lastExpression string
--- The tics untill the player switches to lastExpression.
--- @field expressionTics tic_t
--- The scale of the expression.
--- @field expressionScale fixed_t
--- If the player should be forced to use Super sprites.
--- @field useSuper boolean
--- If this is valid, the player is requesting to team. Anyone can press Toss Flag by them to accept it, and kill off this mobj if it doesn't die within 30 seconds.
--- @field teamMobj mobj_t|nil
--- The current selected player for pre-game team management.
--- @field selectedTeamPlayer integer
--- The current selected question for Quiz Time.
--- @field quizTimeSelection integer
--- If this is true, the player has selected their selection for Quiz Time.
--- @field quizTimeSelected boolean
--- If this is true, the player is qualified to be in the intermission.
--- @field qualified boolean
--- If this is a string, this is the current song playing for the player, which overrides FHN.globalMusic.
--- @field music string|nil
--- If this is valid, this determines if the music should loop or not. If heistRound_t.music is valid, you can guarantee this would be as well.
--- @field musicLoop boolean|nil

setmetatable(FH.characterHealths, { -- NOTE: maybe not the best way to do this? -pac
	__index = function(self, key)
		local ogValue = rawget(self, key)

		if ogValue == nil then
			return 100*FU
		end
		return ogValue
	end
})

--- Initalizes the player's round variables. Should be called once per-round.
--- @param player player_t
--- @return heistPlayerRound_t
function FH:initPlayerRound(player)
	local gametype = FH:isMode()

	player.normalspeed = skins[player.skin].normalspeed
	player.accelstart = skins[player.skin].accelstart
	player.acceleration = skins[player.skin].acceleration

	--- @type heistPlayerRound_t
	local playerRound = {
		profit = 0,
		stasis = false,
		selectedSkinTime = 0,
		instaShieldCooldown = 0,
		pregameState = "character",
		downed = false,
		downedTime = 0,
		canUseInstaShield = true,
		health = FH.characterHealths[skins[player.skin].name],
		skin = player.skin,
		canUseBlock = true,
		blockMaxStrength = FU,
		blockStrength = FU,
		blockChargeCooldown = 0,
		blockCooldown = 0,
		spectator = false,
		mapSelection = 2,
		mapVote = false,
		collectibles = {},
		profitLog = {},
		profitUI = {time = -1, lastTime = -1},
		pregameMenuSelection = 1,
		pregameMenuLerp = 0,
		pregameMenuPath = {},
		expression = "default",
		lastExpression = "",
		expressionTics = 0,
		expressionScale = FU,
		useSuper = false,
		selectedTeamPlayer = 1,
		quizTimeSelection = 1,
		quizTimeSelected = false,
		qualified = false,
		music = nil
	}

	player.hr = playerRound
	gametype:playerInit(player, FHR.currentState)

	return playerRound
end

--- The teaming data for the player.
--- @class heistTeam_t
--- The players within the team. [1] is the team leader.
--- @field players player_t[]

--- Only initalizes the team, but doesn't set it as heistGlobal.team, unlike the other functions. This can be used for re-initalization when necessary.
--- @param player player_t
--- @return heistTeam_t
function FH:initTeam(player)
	--- @type heistTeam_t
	local heistTeam_t = {
		players = {player}
	}

	return heistTeam_t
end

--- Add fields to player_t
--- @class player_t
--- @field hr heistPlayerRound_t?
--- @field hg heistPlayerGlobal_t?

--- @param player player_t
--- @param gametype heistGametype_t
local function initChecks(player, gametype)
	if not player.hg then
		FH:initPlayerGlobal(player)
	end
	if not player.hr then
		FH:initPlayerRound(player)
	end
end

--- @param player player_t
addHook("PlayerSpawn", function(player)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end

	initChecks(player, gametype)
end)

addHook("PreThinkFrame", function()
	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end

	for player in players.iterate do
		initChecks(player, gametype)

		player.hg.lastSidemove = player.hg.sidemove
		player.hg.lastForwardmove = player.hg.forwardmove
		player.hg.lastButtons = player.hg.buttons

		player.hg.sidemove = player.cmd.sidemove
		player.hg.forwardmove = player.cmd.forwardmove
		player.hg.buttons = player.cmd.buttons

		if player.hr.stasis then
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

	if player.hr.spectator and player.mo and player.mo.health then
		player.spectator = true
	end

	if player.hr.useSuper and player.mo then
		player.mo.eflags = $|MFE_FORCESUPER
	elseif player.mo then
		player.mo.eflags = $ & ~MFE_FORCESUPER
	end

	if player.hr.forcedPosition and player.mo and player.mo.health and not player.spectator then
		P_SetOrigin(player.mo,
			player.hr.forcedPosition.x,
			player.hr.forcedPosition.y,
			player.hr.forcedPosition.z
		)
		player.drawangle = player.hr.forcedPosition.angle
		player.mo.momx = 0
		player.mo.momy = 0
		player.mo.momz = 0
		player.mo.state = S_PLAY_STND
		player.mo.frame = ($ & ~FF_FRAMEMASK)|A
		player.mo.tics = -1
	end

	local state = FH.gamestates[FHR.currentState]

	state:playerUpdate(player)
	gametype:playerUpdate(player, FHR.currentState)
end)

--- @param player player_t
addHook("PlayerQuit", function(player)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end

	initChecks(player, gametype)

	if player.hg then
		FH:finishTeam(player)
	end

	player.hasLeftServer = true -- used internally, lets face it the players quitting anyway this doesnt matter a single bit LOL

	local state = FH.gamestates[FHR.currentState]

	state:playerQuit(player)
	gametype:playerQuit(player, FHR.currentState)
end)

--- @param target mobj_t
addHook("MobjDeath", function(target)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end
	if not target.player then return end

	initChecks(target.player, gametype)

	FH:setPlayerExpression(target.player, "dead", 5 * TICRATE)
	gametype:playerDeath(target.player, FHR.currentState)
end, MT_PLAYER)

addHook("ThinkFrame", function()
	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end

	for player in players.iterate do
		initChecks(player, gametype)

		-- TODO: make our own counter that accounts for fixed values.
		-- UPD: this is half done, need to make the scoreboard
		player.score = player.hr.profit/FU
	end
end)

-- require needed external luas
dofile("player/profit.lua")
dofile("player/instashield.lua")
dofile("player/block.lua")
dofile("player/pvp.lua")
dofile("player/health.lua")
dofile("player/expression.lua")
dofile("player/teaming.lua")