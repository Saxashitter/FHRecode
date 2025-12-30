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
		lastButtons = player.cmd.buttons
	}

	print("global player initalization")
	
	player.heistGlobal = playerGlobal
	return playerGlobal
end

--- House-keeping for players per-round.
--- @class heistPlayerRound_t
--- The player's profit counter. Gained from killing enemies, collecting rings, destroying monitors, and hurting players. This would normally be what determines if they win or not.
--- @field profit fixed_t
--- Tics until' the Insta-Shield can be used again for the player.
--- @field instaShieldCooldown number
--- If this is set to a table containing x, y, z and angle positions. The player will forcefully teleport here and be unable to move until' this is set to false.
--- @field forcedPosition table?
--- Set this to true to stop the player from pressing any inputs whatsoever. This should be used over PF_STASIS due to it resetting ALL the player's buttons, as well as ensuring compatibility with menus.
--- @field stasis boolean
--- Used during Pre-Game for animations in the UI.
--- @field selectedSkinTime number
--- Decides the current state of the menu for Pre-Game.
--- @field pregameState string
--- The last skin the player had enabled before switching. It's only purpose is for the Pre-Game UI.
--- @field lastSkin INT32|nil
--- The last direction the player switched characters towards. It's only purpose is for the Pre-Game UI. Either -1 or 1.
--- @field lastSwap number|nil
--- If this is true, the player is determined as downed. They will be forced into a crawling state, and can barely do anything. They will be revived once downedTime hits 0.
--- @field downed boolean
--- Set the timer for the player to be downed in tics. If set to 0, then the timer won't be active.
--- @field downedTime number
--- Set this to false if you don't want the player to use the insta-shield. Defaults to true.
--- @field canUseInstaShield boolean
--- Set this to false if you don't want the player to use the block. Defaults to true.
--- @field canUseBlock boolean
--- The block's max strength it can reach to.
--- @field blockMaxStrength fixed_t
--- The block's current strength.
--- @field blockStrength fixed_t
--- The cooldown until' the block can start recharging.
--- @field blockChargeCooldown number
--- The cooldown until' the player can use the block again.
--- @field blockCooldown number
--- If the player is spectator, this will be true. Used instead of player.spectator due to the chance that the player somehow stops being a spectator.
--- @field spectator boolean
--- The player's current health.
--- @field health fixed_t
--- If this is set to a number, the player will be forced to that skin.
--- @field skin number|nil

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
		canUseBlock = true,
		blockMaxStrength = FU,
		blockStrength = FU,
		blockChargeCooldown = 0,
		blockCooldown = 0,
		spectator = false
	}
	
	print("round player initalization")

	player.heistRound = playerRound
	gametype:playerInit(player, FHR.currentState)

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

		player.heistGlobal.lastSidemove = player.heistGlobal.sidemove
		player.heistGlobal.lastForwardmove = player.heistGlobal.forwardmove
		player.heistGlobal.lastButtons = player.heistGlobal.buttons

		player.heistGlobal.sidemove = player.cmd.sidemove
		player.heistGlobal.forwardmove = player.cmd.forwardmove
		player.heistGlobal.buttons = player.cmd.buttons

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

	if player.heistRound.spectator and player.mo and player.mo.health then
		player.spectator = true
	end

	if player.heistRound.forcedPosition and player.mo and player.mo.health and not player.spectator then
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

	state:playerUpdate(player)
	gametype:playerUpdate(player, FHR.currentState)
end)

--- @param player player_t
addHook("PlayerQuit", function(player)
	print("Player quit.")

	--- @type heistGametype_t|false
	local gametype = FH:isMode()

	if not gametype then return end

	initChecks(player, gametype)
	player.hasLeftServer = true -- used internally, lets face it the players quitting anyway this doesnt matter a single bit LOL

	local state = FH.gamestates[FHR.currentState]

	state:playerQuit(player)
	gametype:playerQuit(player, FHR.currentState)
end)

--- @param target mobj_t
addHook("MobjDeath", function(target)
	print("Player death.")

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

-- require needed external luas
dofile("player/profit.lua")
dofile("player/instashield.lua")
dofile("player/block.lua")
dofile("player/pvp.lua")
dofile("player/health.lua")