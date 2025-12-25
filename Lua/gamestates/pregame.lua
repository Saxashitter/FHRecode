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
		FH:setGamestate("game")

		for player in players.iterate do
			if not player.heistRound then return end

			player.heistRound.stasis = false
			player.mo.tics = states[player.mo.state].tics
			player.cmd.sidemove = player.heistGlobal.sidemove
			player.cmd.forwardmove = player.heistGlobal.forwardmove
			player.cmd.buttons = player.heistGlobal.buttons
			player.lastbuttons = player.heistGlobal.buttons

			player.heistGlobal.skin = player.skin
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
	local dir = player.heistRound.sidemove > 0 and 1 or -1
	local inputRegister = 50/4

	if abs(player.heistRound.sidemove) >= inputRegister
	and abs(player.heistRound.lastSidemove) < inputRegister then
		print("Moving towards: "..dir)

		local newSkin = player.skin + dir

		if newSkin < 0 then
			newSkin = #skins - 1
		end

		if newSkin > #skins - 1 then
			newSkin = 0
		end

		R_SetPlayerSkin(player, newSkin)
		player.heistRound.selectedSkinTime = leveltime
	end
end

FH.gamestates.pregame = gamestate