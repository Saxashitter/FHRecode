local gamestate = {}

gamestate.timeLeft = 5 * TICRATE

function gamestate:init()
	S_StartSound(nil, sfx_s1ca)
	S_StartSoundAtVolume(nil, sfx_kc5c, 75)
	FHN.titleCardTime = self.timeLeft
	S_FadeMusic(0, 2 * MUSICRATE)
end

function gamestate:load()
	-- apply MF_NOTHINK to all mobjs to ensure nothing moves. do this once as well so we dont gotta worry about lag
	for mobj in mobjs.iterate() do
		mobj.flags = $|MF_NOTHINK
	end
end

function gamestate:update()
	
	FHN.titleCardTime = $ - 1
	
	if not FHN.titleCardTime then
		for mobj in mobjs.iterate() do
			if not mobj.__hasNoThink then
				mobj.flags = $ & ~MF_NOTHINK
			end
			mobj.__hasNoThink = nil
		end
		
		-- constantly set stasis to true even for new players
		-- TODO: take advantage of PlayerSpawn so this doesn't run every tic
		for player in players.iterate do
			if not player.heistRound then continue end

			player.heistRound.stasis = false
			player.mo.tics = states[player.mo.state].tics
			player.cmd.sidemove = player.heistGlobal.sidemove
			player.cmd.forwardmove = player.heistGlobal.forwardmove
			player.cmd.buttons = player.heistGlobal.buttons
			player.lastbuttons = player.heistGlobal.buttons
		end

		FHN.titleCardEndTime = leveltime
		FH:changeMusic()
		FH:setGamestate("game")
		return
	end

	for player in players.iterate do
		if not player.heistRound then continue end

		player.heistRound.stasis = true
		player.mo.momx = 0
		player.mo.momy = 0
		player.mo.momz = 0
		player.mo.tics = -1
	end
end

function gamestate:preUpdate() end
function gamestate:playerUpdate() end
function gamestate:playerQuit() end

FH.gamestates.titlecard = gamestate