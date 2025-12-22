

--- Checks if the player is in a exit sector.
--- @param player player_t
function FH:isPlayerExiting(player)
	if player.mo.subsector.sector.specialflags & SSF_EXIT > 0 then
		return true
	end

	for fof in player.mo.subsector.sector.ffloors() do
		if player.mo.z < fof.bottomheight then continue end
		if player.mo.z+player.mo.height > fof.topheight then continue end
		if fof.sector.specialflags & SSF_EXIT == 0 then continue end

		return true
	end

	return false
end

--- @param player player_t
addHook("PlayerThink", function(player)
	if not player.heistGlobal then
		FH:initPlayerGlobal(player)
	end
	if not player.heistRound then
		FH:initPlayerRound(player)
	end

	player.heistRound

	if FH:isPlayerExiting(player) then
		print("we leaving")
	end
end)