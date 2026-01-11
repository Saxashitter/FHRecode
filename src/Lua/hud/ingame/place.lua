local ui = {
	x = 16,
	y = 26,
	placeX = 96,
	flags = V_SNAPTOLEFT|V_SNAPTOTOP
}

--- @param v videolib
--- @param player player_t
function ui:draw(v, player)
	local place = 0

	if player and player.hr and not player.hr.spectator then
		place = FH:getPlayerPlace(player)
	end

	local stt = v.cachePatch("FH_PLACE_STT")
	local placeX = self.placeX

	v.draw(self.x, self.y, stt, self.flags)
	FH:drawSTT(v, placeX * FU, self.y * FU, FU, place, self.flags, FU, 0)
end

return ui, "time", 1, "overlay"