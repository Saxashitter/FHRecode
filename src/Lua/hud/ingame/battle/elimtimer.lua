local elimTimer = {
	x = 320 - 12,
	y = 12,
	flags = V_SNAPTORIGHT|V_SNAPTOTOP,

	freeTimeText = "Players will be\neliminated in %d",
	dyingText = "%s will be\neliminated in %d",
	showdownText = "Showdown\nDying = Elimination"
}

function elimTimer:draw(v)
	local gametype = FH:isMode()
	if not gametype then return end
	if not gametype.isBattle then return end

	if FHR.currentState ~= "game" then return end

	local string = self.freeTimeText:format(FHR.freeTimeTics/TICRATE)
	local player = gametype:getWorstPlayer()
	local playerName = player and player.name or "Nobody"
	local color = 0

	if not FHR.freeTimeTics then
		if player == displayplayer then
			color = V_REDMAP
		end

		string = self.dyingText:format(playerName, FHR.ticsUntilDeath/TICRATE)
	end
	if FHR.showdown then
		string = self.showdownText
	end

	SSL.drawString(v, self.x, self.y, string, "TNYFN%03d", self.flags, FU, 0, color)
end

return elimTimer, "battleEliminationTimer", 1, "overlay"