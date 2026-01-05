local gamestate = {}
gamestate.countdown = 3 * TICRATE

sfxinfo[freeslot("sfx_fh_cd5")].caption = "Five!"
sfxinfo[freeslot("sfx_fh_cd4")].caption = "Four!"
sfxinfo[freeslot("sfx_fh_cd3")].caption = "Three!"
sfxinfo[freeslot("sfx_fh_cd2")].caption = "Two!"
sfxinfo[freeslot("sfx_fh_cd1")].caption = "One!"
sfxinfo[freeslot("sfx_fh_cd0")].caption = "GO!!"

local function unstasisPlayers()
	-- constantly set stasis to true even for new players
	-- TODO: take advantage of PlayerSpawn so this doesn't run every tic
	for player in players.iterate do
		if not player.heistRound then continue end

		player.heistRound.stasis = false
		player.cmd.sidemove = player.heistGlobal.sidemove
		player.cmd.forwardmove = player.heistGlobal.forwardmove
		player.cmd.buttons = player.heistGlobal.buttons
		player.lastbuttons = player.heistGlobal.buttons

		if player.cmd.buttons & BT_JUMP then
			player.pflags = $|PF_JUMPDOWN
		end
		if player.cmd.buttons & BT_SPIN then
			player.pflags = $|PF_SPINDOWN
		end

		if not player.mo then continue end
		if not player.mo.spawnpoint then continue end

		player.mo.tics = states[player.mo.state].tics
		player.mo.alpha = FU
		player.mo.state = S_PLAY_ROLL
		player.pflags = $|PF_SPINNING
		player.powers[pw_flashing] = 2 * TICRATE
		P_InstaThrust(player.mo, FixedAngle(player.mo.spawnpoint.angle * FU), player.normalspeed)
		P_SetObjectMomZ(player.mo, 12 * player.mo.scale)
	end
end


function gamestate:init()
	FHR.gameCountdown = self.countdown
	FHR.titleCardEndTime = leveltime

	for mobj in mobjs.iterate() do
		if not mobj.__hasNoThink then
			mobj.flags = $ & ~MF_NOTHINK
		end
		mobj.__hasNoThink = nil
	end

	for player in players.iterate do
		if not player.mo then continue end

		local fallback
		local found = false

		for mapthing in mapthings.iterate do
			if mapthing.type == 1 then
				fallback = mapthing
			end
			if mapthing.type == #player + 1 then
				player.mo.spawnpoint = mapthing
				found = true
				break
			end
		end

		if found then continue end

		player.mo.spawnpoint = fallback
	end
end

function gamestate:load()
end

function gamestate:update()
	if FHR.gameCountdown then
		if FHR.gameCountdown % TICRATE == 0 then
			local sound = _G["sfx_fh_cd"..FHR.gameCountdown / TICRATE]

			if sound ~= nil then
				S_StartSound(nil, sound)
			end
		end

		FHR.gameCountdown = $ - 1

		if not FHR.gameCountdown then
			unstasisPlayers()
			S_StartSound(nil, sfx_fh_cd0)
			FH:changeMusic()
		end
	end

	-- update modifiers
	for k, v in ipairs(FHR.modifiers) do
		local modifier = FH.modifiers.all[v]

		modifier:update()
	end
end

function gamestate:preUpdate()
end

--- @param player player_t
function gamestate:playerUpdate(player)
	if player.heistRound.skin and player.skin ~= player.heistRound.skin then
		R_SetPlayerSkin(player, player.heistRound.skin)
	end

	-- update modifiers
	for k, v in ipairs(FHR.modifiers) do
		local modifier = FH.modifiers.all[v]

		modifier:playerUpdate(player)
	end
end

function gamestate:playerQuit() end

COM_AddCommand("fh_endgame", function(player)
	FH:endGame()
end, COM_ADMIN)

FH.gamestates.game = gamestate