--- @param v videolib
return function(v)
	local screenWidth = v.width() * FU / v.dupx()
	local screenHeight = v.height() * FU / v.dupy()
	
	local state = FH.gamestates[FHR.currentState]
	local tics = leveltime - FHR.intermissionStartTime - state.gameScreenEnd
	local beforeBeatTics = state.intermissionBeat - tics
	local afterTics = max(0, tics - state.intermissionBeat)
	local resultsTics = max(0, tics - state.resultsTime)

	local portraitSlideTime = FH:easeTime(afterTics, 24, 5)
	
	if tics < state.intermissionBeat then
		v.drawFill()
		if tics > 0 then
			local trans = 10 - min(tics, 10)
			SSL.drawString(v, 160, 100, "This game's winner is...", "TNYFN%03d", V_10TRANS * trans, FU/2, FU/2)
		end
		if beforeBeatTics < 10 then
			FH:drawPaletteRect(v, 0, 0, screenWidth, screenHeight, 0, (V_10TRANS * beforeBeatTics)|V_SNAPTOLEFT|V_SNAPTOTOP)
		end
		return
	end

	local winner = FHR.winningPlayers[1]
	local background = v.cachePatch("FH_S2BACKGROUND_GREEN")
	local nameBackground = v.cachePatch("FH_NAMEBACKGROUND")
	
	local backgroundStartX = -leveltime * FU / 3
	local backgroundStartY = -leveltime * FU / 3
	
	local noContest = winner == nil
	local name = noContest and "No Contest" or winner.name
	local color = noContest and SKINCOLOR_WHITE or winner.color

	for y = backgroundStartY, screenHeight, background.height * FU do
		for x = backgroundStartX, screenWidth, background.width * FU do
			v.drawScaled(x, y, FU, background, V_SNAPTOLEFT|V_SNAPTOTOP, v.getColormap(nil, skincolors[color].invcolor))
		end
	end

	if not noContest then
		local portrait = FH:getCharPortrait(v, winner.skin, true)
		local portraitX = 220*FU
		local portraitY = 110*FU
	
		-- ease em in
		portraitX = ease.outback(portraitSlideTime, 160 * FU - portrait.width * FU / 2, $, 2 * FU)
		portraitY = ease.outback(portraitSlideTime, 200 * FU, $, 2 * FU)

		v.drawScaled(portraitX + 4 * FU, portraitY + 4 * FU, FU, portrait, V_SNAPTORIGHT|V_SNAPTOBOTTOM, v.getColormap(TC_BLINK, color))
		v.drawScaled(portraitX, portraitY, FU, portrait, V_SNAPTORIGHT|V_SNAPTOBOTTOM, v.getColormap(nil, color))
	end

	v.draw(0, 0, nameBackground, V_SNAPTOTOP|V_SNAPTOLEFT)

	local textY = 8
	SSL.drawString(v, 8, textY, name, "LTFNT%03d", V_SNAPTOTOP|V_SNAPTOLEFT, 0, 0, skincolors[color].chatcolor, 0, 0)
	textY = $ + 24

	if not noContest then
		SSL.drawString(v, 8, textY, "Recoded your mom!", "TNYFN%03d", V_SNAPTOTOP|V_SNAPTOLEFT, 0, 0, skincolors[color].chatcolor)
		textY = $ + 10

		local format = "%s (x%d): $%.2f"
		for k, log in ipairs(winner.log) do
			local string = format:format(log.tag, log.timesRan, log.profit)
			SSL.drawString(v, 8, textY, string, "TNYFN%03d", V_SNAPTOLEFT|V_SNAPTOTOP, 0, 0, V_GREENMAP, 0, 0)
			textY = $ + 10
		end

		SSL.drawString(v, 8, textY, "Work in progress.", "TNYFN%03d", V_SNAPTOLEFT|V_SNAPTOTOP, 0, 0, V_REDMAP, FU)
	end
	if afterTics < 10 then
		FH:drawPaletteRect(v, 0, 0, screenWidth, screenHeight, 0, (V_10TRANS * afterTics)|V_SNAPTOLEFT|V_SNAPTOTOP)
	end
end