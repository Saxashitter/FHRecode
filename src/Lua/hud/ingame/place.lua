local function getPlayerPlace(player)
	local place = 1

	for other in players.iterate do
		if other == player then continue end
		if not other.heistRound then continue end
		if other.heistRound.spectator then continue end
		if other.heistRound.profit <= player.heistRound.profit then continue end

		place = place + 1
	end

	return place
end

local ui = {
	x = 16,
	y = 26,
	placeX = 120,
	flags = V_SNAPTOLEFT|V_SNAPTOTOP
}

--- @param v videolib
--- @param player player_t
function ui:draw(v, player)
	local place = 0

	if player and player.heistRound and not player.heistRound.spectator then
		place = getPlayerPlace(player)
	end

	local stt = v.cachePatch("FH_PLACE_STT")
	local placeX = self.placeX

	v.draw(self.x, self.y, stt, self.flags)
	FH:drawSTT(v, placeX * FU, self.y * FU, FU, place, self.flags, FU, 0)
end

return ui, "time", 1, "overlay"