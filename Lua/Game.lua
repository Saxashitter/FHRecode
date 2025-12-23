--- Checks if the player is in a exit sector. Mainly used to start the escape sequence in Escape modes.
--- @param player player_t
function FH:isPlayerInExitSector(player)
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
end)

--- @param network function
addHook("NetVars", function(network)
	FHN = network($)
	FHR = network($)
end)