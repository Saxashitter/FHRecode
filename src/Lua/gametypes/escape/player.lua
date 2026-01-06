local escape = _FH_ESCAPE

--- @class heistPlayerRound_t
--- If set to true, the player has escaped in one of the Escape modes.
--- @field escaped boolean

--- Checks if the player is in a exit sector. Mainly used to start the escape sequence in Escape modes.
--- @param player player_t
function escape:isPlayerInExitSector(player)
	if player.mo.subsector.sector.specialflags & SSF_EXIT > 0 then
		return true
	end

	for fof in player.mo.subsector.sector.ffloors() do
		if player.mo.z < fof.bottomheight then continue end
		if player.mo.z + player.mo.height > fof.topheight then continue end
		if fof.sector.specialflags & SSF_EXIT == 0 then continue end

		return true
	end

	return false
end

--- @param player player_t
--- @param currentState string
function escape:playerUpdate(player, currentState)
	if currentState ~= "game" then return end
	if not player.mo then return end
	if not player.mo.health then return end

	if self:isPlayerInExitSector(player) and not FHR.escape then
		escape:startEscape(player)
	end

	if player.heistRound.escaped then
		---@diagnostic disable-next-line: assign-type-mismatch
		player.powers[pw_flashing] = TICRATE
	end
end

--- @param player player_t
--- @param currentState string
function escape:playerDeath(player, currentState)
	if currentState ~= "game" then return end
	if not FHR.escape then return end

	player.heistRound.spectator = true
	self:safeFinish()
end

--- @param player player_t
--- @param currentState string
function escape:playerInit(player, currentState)
	if currentState ~= "game" then return end
	if not FHR.escape then return end

	player.heistRound.spectator = true
end

--- @param player player_t
--- @param currentState string
function escape:playerQuit(player, currentState)
	if currentState ~= "game" then return end

	self:safeFinish()
end

--- @param player player_t
--- @param profit fixed_t
function escape:addProfit(player, profit)
	if FHR.escape and FHR.escapeTime <= self.timesUpStart then return end
	local place = FH:getPlayerPlace(player)

	if place == 1 and not player.heistRound.expressionTics then
		for otherPlayer in players.iterate do
			if otherPlayer == player then continue end
			if not otherPlayer.heistRound then continue end

			if otherPlayer.heistRound.expression == "1st" or (otherPlayer.heistRound.expressionTics and otherPlayer.heistRound.lastExpression == "1st") then
				FH:setPlayerExpression(otherPlayer, "default", 0)
			end
		end

		FH:setPlayerExpression(player, "1st")
	end
end