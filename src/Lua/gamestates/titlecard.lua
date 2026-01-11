local gamestate = {}

gamestate.timeLeft = 5 * TICRATE

function gamestate:init()
	S_StartSound(nil, sfx_s1ca)
	S_StartSoundAtVolume(nil, sfx_kc5c, 75)
	FHR.titleCardTime = self.timeLeft
	S_FadeMusic(0, 2 * MUSICRATE)
end

function gamestate:load()
	
end

function gamestate:update()
	
	FHR.titleCardTime = $ - 1
	
	if not FHR.titleCardTime then
		FHR.titleCardEndTime = leveltime
		FH:setGamestate("game")
		return
	end

	for player in players.iterate do
		if not player.hr then continue end

		player.hr.stasis = true

		if player.mo then
			player.mo.momx = 0
			player.mo.momy = 0
			player.mo.momz = 0
			player.mo.tics = -1
			player.mo.alpha = 0
		end
	end
end

function gamestate:preUpdate() end
function gamestate:playerUpdate() end
function gamestate:playerQuit() end

FH.gamestates.titlecard = gamestate