local gamestate = {}
local skipTitlecard = true

gamestate.timeLeft = 60 * TICRATE

-- view game.lua for gamestate documentation

function gamestate:init()
	FHR.pregameTimeLeft = self.timeLeft

	for player in players.iterate do
		if not player.heistRound then return end

		player.heistRound.stasis = true
	end
end

function gamestate:load()
	FH:changeMusic("FH_PRG")
	
	-- apply MF_NOTHINK to all mobjs to ensure nothing moves. do this once as well so we dont gotta worry about lag
	for mobj in mobjs.iterate() do
		mobj.__hasNoThink = mobj.flags & MF_NOTHINK > 0
		mobj.flags = $|MF_NOTHINK
	end
end

function gamestate:update()
	if FHR.pregameTimeLeft then
		FHR.pregameTimeLeft = $ - 1
	else
		self:switch()
		return
	end

	for player in players.iterate do
		if not player.heistRound then continue end

		player.heistRound.stasis = true

		if player.mo then
			player.mo.momx = 0
			player.mo.momy = 0
			player.mo.momz = 0
			player.mo.tics = -1
			player.mo.alpha = 0
		end
	end
end

function gamestate:switch()
	for player in players.iterate do
		if not player.heistRound then continue end

		player.heistRound.skin = player.skin
	end

	if skipTitlecard then
		FH:setGamestate("game")
		return
	end

	FH:setGamestate("titlecard")
end

function gamestate:canSwitch()
	local count = 0
	local finishedCount = 0

	for player in players.iterate do
		if not player.heistRound then continue end
		---@diagnostic disable-next-line: undefined-field
		if player.hasLeftServer then continue end

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

	local x, _ = FH:isMovePressed(player, inputRegister)
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

			while not R_SkinUsable(player, newSkin) do
				newSkin = $ + x
				if newSkin < 0 then
					newSkin = #skins - 1
				end

				if newSkin > #skins - 1 then
					newSkin = 0
				end
			end

			player.heistRound.lastSkin = player.skin
			player.heistRound.lastSwap = x
			player.heistRound.selectedSkinTime = leveltime
			S_StartSound(nil, sfx_kc39, player)
			R_SetPlayerSkin(player, newSkin)
		end

		if jump then
			-- to waiting state you go
			player.heistRound.pregameState = "waiting"
			if self:canSwitch() then
				self:switch()
			else
				S_StartSound(nil, sfx_kc5e, player)
			end
		end
	elseif player.heistRound.pregameState == "waiting" then
		if spin then
			-- to character state you go
			player.heistRound.pregameState = "character"
		end
	end
end

function gamestate:playerQuit()
	if self:canSwitch() then
		self:switch()
	end
end

FH.gamestates.pregame = gamestate