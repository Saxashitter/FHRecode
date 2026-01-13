--- @param v videolib
return function(v)
	local gametype = FH:isMode() --[[@as heistGametype_t]]
	local screenWidth = v.width() * FU / v.dupx()
	local screenHeight = v.height() * FU / v.dupy()
	
	local state = FH.gamestates[FHR.currentState]
	local tics = leveltime - FHR.intermissionStartTime - state.gameScreenEnd
	local beforeBeatTics = state.intermissionBeat - tics
	local afterTics = max(0, tics - state.intermissionBeat)
	local resultsTics = max(0, tics - state.resultsTime)
	
	-- =====================
	-- PRE-BEAT SCREEN
	-- =====================

	if tics < state.intermissionBeat then
		v.drawFill()

		if tics > 0 then
			local trans = 10 - min(tics, 10)
			SSL.drawString(
				v, 160, 100,
				"This game's winner is...",
				"TNYFN%03d",
				V_10TRANS * trans,
				FU/2, FU/2
			)
		end

		if beforeBeatTics < 10 then
			FH:drawPaletteRect(
				v,
				0, 0,
				screenWidth, screenHeight,
				0,
				(V_10TRANS * beforeBeatTics)
				|V_SNAPTOLEFT|V_SNAPTOTOP
			)
		end

		return
	end

	-- =====================
	-- BACKGROUND
	-- =====================

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
			v.drawScaled(
				x, y, FU,
				background,
				V_SNAPTOLEFT|V_SNAPTOTOP,
				v.getColormap(nil, skincolors[color].invcolor)
			)
		end
	end

	-- =====================
	-- PORTRAITS
	-- =====================

	if not noContest then
		local portrait = FH:getCharPortrait(v, winner.skin, true)

		-- collect team member portraits FIRST
		local teamPortraits = {}
		local iter = 1

		local portraitSlideTime = FH:easeTime(afterTics, 24, 5)
		-- ease winner + team in
		local portraitX = ease.outback(
			portraitSlideTime,
			160 * FU - portrait.width * FU / 2,
			220 * FU, 2 * FU
		)
		local portraitY = ease.outback(
			portraitSlideTime,
			200 * FU,
			110 * FU, 2 * FU
		)

		if #winner.team.players > 1 and gametype.teams then
			for k, member in ipairs(winner.team.players) do
				if winner.player.valid and member == winner.player then
					continue
				end

				local portraitSlideTime = FH:easeTime(afterTics, 24, 5 * (iter + 1))
				-- ease winner + team in
				local portraitX = ease.outback(
					portraitSlideTime,
					160 * FU - portrait.width * FU / 2,
					220 * FU, 2 * FU
				)
				local portraitY = ease.outback(
					portraitSlideTime,
					200 * FU,
					110 * FU, 2 * FU
				)
	
				local memberPortrait =
					FH:getCharPortrait(v, skins[member.skin].name, true)

				table.insert(teamPortraits, {
					portrait = memberPortrait,
					x = portraitX - (80 * FU) * iter,
					y = portraitY,
					color = member.skincolor
				})

				iter = $ + 1
			end
		end

		-- =====================
		-- DRAW TEAM (BACK → FRONT)
		-- =====================

		for i = #teamPortraits, 1, -1 do
			local p = teamPortraits[i]

			v.drawScaled(
				p.x + 4 * FU,
				p.y + 4 * FU,
				FU,
				p.portrait,
				V_SNAPTORIGHT|V_SNAPTOBOTTOM,
				v.getColormap(TC_BLINK, p.color)
			)

			v.drawScaled(
				p.x,
				p.y,
				FU,
				p.portrait,
				V_SNAPTORIGHT|V_SNAPTOBOTTOM,
				v.getColormap(nil, p.color)
			)
		end

		-- =====================
		-- DRAW WINNER LAST
		-- =====================

		v.drawScaled(
			portraitX + 4 * FU,
			portraitY + 4 * FU,
			FU,
			portrait,
			V_SNAPTORIGHT|V_SNAPTOBOTTOM,
			v.getColormap(TC_BLINK, color)
		)

		v.drawScaled(
			portraitX,
			portraitY,
			FU,
			portrait,
			V_SNAPTORIGHT|V_SNAPTOBOTTOM,
			v.getColormap(nil, color)
		)
	end

	-- =====================
	-- NAME + RESULTS
	-- =====================

	v.draw(0, 0, nameBackground, V_SNAPTOTOP|V_SNAPTOLEFT)

	local textY = 8
	SSL.drawString(
		v, 8, textY,
		name,
		"LTFNT%03d",
		V_SNAPTOTOP|V_SNAPTOLEFT,
		0, 0,
		skincolors[color].chatcolor,
		0, 0
	)
	textY = $ + 24

	if not noContest then
		SSL.drawString(
			v, 8, textY,
			"Recoded your mom!",
			"TNYFN%03d",
			V_SNAPTOTOP|V_SNAPTOLEFT,
			0, 0,
			skincolors[color].chatcolor
		)
		textY = $ + 10

		local format = "%s (x%d): %s $%.2f"
		for k, log in ipairs(winner.log) do
			local string = format:format(
				log.tag,
				log.timesRan,
				log.profit > 0 and "+" or "-",
				abs(log.profit)
			)

			local map = log.profit > 0 and V_GREENMAP or V_REDMAP

			SSL.drawString(
				v, 8, textY,
				string,
				"TNYFN%03d",
				V_SNAPTOLEFT|V_SNAPTOTOP,
				0, 0,
				map,
				0, 0
			)

			textY = $ + 10
		end

		SSL.drawString(
			v, 8, textY,
			"Work in progress.",
			"TNYFN%03d",
			V_SNAPTOLEFT|V_SNAPTOTOP,
			0, 0,
			V_REDMAP,
			FU
		)
	end

	-- =====================
	-- FADE OUT
	-- =====================

	if afterTics < 10 then
		FH:drawPaletteRect(
			v,
			0, 0,
			screenWidth, screenHeight,
			0,
			(V_10TRANS * afterTics)
			|V_SNAPTOLEFT|V_SNAPTOTOP
		)
	end
end
