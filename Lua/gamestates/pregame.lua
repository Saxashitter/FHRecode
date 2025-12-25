local gamestate = {}

gamestate.timeLeft = 5 * TICRATE

function gamestate:init()
	FHN.pregameTimeLeft = self.timeLeft

	for player in players.iterate do
		if not player.heistRound then return end

		player.heistRound.stasis = true
	end
end
function gamestate:update()
	if FHN.pregameTimeLeft then
		FHN.pregameTimeLeft = $ - 1
	else
		print("Switching to main state.")
		FH:setGamestate("game")

		for player in players.iterate do
			if not player.heistRound then return end

			player.heistRound.stasis = false
			player.mo.tics = states[player.mo.state].tics
			player.cmd.sidemove = player.heistGlobal.sidemove
			player.cmd.forwardmove = player.heistGlobal.forwardmove
			player.cmd.buttons = player.heistGlobal.buttons
			player.lastbuttons = player.heistGlobal.buttons
		end

		return
	end

	for player in players.iterate do
		if not player.heistRound then return end

		player.heistRound.stasis = true
		player.mo.momx = 0
		player.mo.momy = 0
		player.mo.momz = 0
		player.mo.tics = -1
	end
end
function gamestate:preUpdate()
end
function gamestate:playerUpdate(player)
	
end

FH.gamestates.pregame = gamestate