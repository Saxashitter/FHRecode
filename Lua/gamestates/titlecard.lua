local gamestate = {}

gamestate.timeLeft = 5 * TICRATE

function gamestate:init()
	S_StartSound(nil, sfx_s1ca)
	S_StartSoundAtVolume(nil, sfx_kc5c, 75)
	FHR.titleCardTime = self.timeLeft
	S_FadeMusic(0, 2 * MUSICRATE)
end

function gamestate:load()
	-- apply MF_NOTHINK to all mobjs to ensure nothing moves. do this once as well so we dont gotta worry about lag
	for mobj in mobjs.iterate() do
		mobj.flags = $|MF_NOTHINK
	end
end

function gamestate:update()
	
	FHR.titleCardTime = $ - 1
	
	if not FHR.titleCardTime then
		for mobj in mobjs.iterate() do
			if not mobj.__hasNoThink then
				mobj.flags = $ & ~MF_NOTHINK
			end
			mobj.__hasNoThink = nil
		end

		FHR.titleCardEndTime = leveltime
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
		player.mo.alpha = 0
	end
end

function gamestate:preUpdate() end
function gamestate:playerUpdate() end
function gamestate:playerQuit() end

FH.gamestates.titlecard = gamestate