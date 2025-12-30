--- @param v videolib
--- @param player player_t
return function(v, player)
	FH.playerIconParallax:draw(v, skins[player and player.skin or 0].name, leveltime)

	SSL.drawString(v, 160, 100, "Waiting...", "STCFN%03d", 0, FU/2, FU/2, nil, nil, nil)
end