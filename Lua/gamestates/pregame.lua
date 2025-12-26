local gamestate = {}

gamestate.timeLeft = 5 * TICRATE

function gamestate:init()
	FHN.pregameTimeLeft = self.timeLeft

	for player in players.iterate do
		if not player.heistRound then return end

		player.heistRound.stasis = true
	end
end

function gamestate:load()
	-- apply MF_NOTHINK to all mobjs to ensure nothing moves. do this once as well so we dont gotta worry about lag

	for mobj in mobjs.iterate() do
		mobj.__hasNoThink = mobj.flags & MF_NOTHINK > 0
		mobj.flags = $|MF_NOTHINK
	end
end

function gamestate:update()
	if FHN.pregameTimeLeft then
		FHN.pregameTimeLeft = $ - 1
	else
		for mobj in mobjs.iterate() do
			if not mobj.__hasNoThink then
				mobj.flags = $ & ~MF_NOTHINK
			end
			mobj.__hasNoThink = nil
		end

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

		FH:setGamestate("game")

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

function gamestate:canSwitch()
	local count = 0
	local finishedCount = 0

	for player in players.iterate do
		if not player.heistRound then return end
		count = $+1

		if player.heistRound.pregameState == "waiting" then
			finishedCount = $+1
		end
	end

	return finishedCount >= count
end

function gamestate:preUpdate()
end

function gamestate:playerUpdate(player)
	local inputRegister = 50/4

	local x, y = FH:isMovePressed(player, inputRegister)
	local jump = FH:isButtonPressed(player, BT_JUMP)
	local spin = FH:isButtonPressed(player, BT_SPIN)

	-- TODO: actual states instead of if checks
	if player.heistRound.pregameState == "character" then
		if x ~= 0 then
			local newSkin = player.skin + x

			if newSkin < 0 then
				newSkin = #skins - 1
			end

			if newSkin > #skins - 1 then
				newSkin = 0
			end

			R_SetPlayerSkin(player, newSkin)
			player.heistRound.selectedSkinTime = leveltime
		end

		if jump then
			-- to waiting state you go
			player.heistRound.pregameState = "waiting"
		end
	elseif player.heistRound.pregameState == "waiting" then
		if spin then
			-- to character state you go
			player.heistRound.selectedSkinTime = leveltime
			player.heistRound.pregameState = "character"
		end
	end
end

FH.gamestates.pregame = gamestate