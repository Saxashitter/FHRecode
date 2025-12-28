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
end

--- @param player player_t
--- @param currentState string
function escape:playerDeath(player, currentState)
	if currentState ~= "game" then return end

	self:safeFinish()
end

--- @param player player_t
--- @param currentState string
function escape:playerQuit(player, currentState)
	if currentState ~= "game" then return end

	self:safeFinish()
end