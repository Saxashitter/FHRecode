local titleCardMenu = {}

titleCardMenu.colorPalette = {
	16
}

local function frameByTime(tics, maxFrame, frameRate)
	return (tics / frameRate) % maxFrame
end

--- @param v videolib
--- @param x fixed_t
--- @param y fixed_t
--- @param xscale fixed_t
--- @param yscale fixed_t|nil
--- @param sprite patch_t
--- @param flags UINT32|nil
--- @param flip boolean|nil
--- @param color colormap|nil
local function drawSprite(v, x, y, xscale, yscale, sprite, flags, flip, color)
	flags = $ or 0
	flip = $ or false
	yscale = $ or xscale

	if flip then
		flags = $|V_FLIP
	end
	
	if xscale < 0 then
		if flip then
			flags = $ & ~V_FLIP
		else
			flags = $|V_FLIP
		end
	end

	v.drawStretched(x, y, xscale, yscale, sprite, flags, color)
end

--- @param v videolib
--- @param player player_t
--- @param camera camera_t
function titleCardMenu:draw(v, player, camera)
	local screenWidth = v.width() * FU / v.dupx()
	local screenHeight = v.height() * FU / v.dupy()

	if FHR.currentState ~= "titlecard" then
		if FHR.currentState == "game" then
			-- draw transition
			local progress = leveltime - FHR.titleCardEndTime

			if progress >= 10 then return end

			FH:drawPaletteRect(v, 0, 0, screenWidth, screenHeight, 31, V_SNAPTOTOP|V_SNAPTOLEFT|(V_10TRANS * progress))
		end

		return
	end

	local state = FH.gamestates[FHR.currentState]
	local progress = state.timeLeft - FHR.titleCardTime

	local ditherLength = 2
	local colors = {
		31,
		skincolors[player.skincolor].ramp[15],
		skincolors[player.skincolor].ramp[14],
		skincolors[player.skincolor].ramp[13],
		skincolors[player.skincolor].ramp[12],
		skincolors[player.skincolor].ramp[11],
		skincolors[player.skincolor].ramp[10],
		skincolors[player.skincolor].ramp[9],
		skincolors[player.skincolor].ramp[8],
		skincolors[player.skincolor].ramp[7],
		skincolors[player.skincolor].ramp[6],
		skincolors[player.skincolor].ramp[5],
		skincolors[player.skincolor].ramp[4],
		skincolors[player.skincolor].ramp[3],
		skincolors[player.skincolor].ramp[2],
		skincolors[player.skincolor].ramp[1],
		skincolors[player.skincolor].ramp[0],
	}

	local backgroundHeight = screenHeight / #colors

	for i = 1, #colors do
		FH:drawPaletteRect(v, 0, backgroundHeight * (#colors - i), screenWidth, backgroundHeight, colors[i], V_SNAPTOLEFT|V_SNAPTOTOP)

		if i < #colors then
			for y = 1, ditherLength do
				local offset = y % 2
				local drawY = backgroundHeight * (#colors - i) + (y - 1) * FU
				local color = colors[i+1]

				for x = 0, screenWidth-1, 2 * FU do
					local drawX = x + offset * FU

					FH:drawPaletteRect(v, drawX, drawY, FU, FU, color, V_SNAPTOLEFT|V_SNAPTOTOP)
				end
			end
		end
	end

	-- le map name
	SSL.drawString(v, 160, 12, G_BuildMapTitle(gamemap), "LTFNT%03d", V_SNAPTOTOP, FU/2, 0, 0, 0, FU)
	SSL.drawString(v, 160, 12 + 24, "Act "..mapheaderinfo[gamemap].actnum, "TNYFN%03d", V_SNAPTOTOP, FU/2, 0, 0, 0, FU)

	-- draw characters
	local floorY = 180 * FU
	local drawScale = FU / 2
	local distance = 70 * drawScale
	local fangX = 160 * FU
	local fang, flipFang = v.getSprite2Patch(
		"fang",
		SPR2_RUN_,
		false,
		frameByTime(leveltime, skins["fang"].sprites[SPR2_RUN_].numframes, 2),
		7
	)

	local tailsX = 160 * FU - distance
	local tailsY = -16 * FU
	local tails, flipTails = v.getSprite2Patch(
		"tails",
		SPR2_FLY_,
		false,
		frameByTime(leveltime, skins["tails"].sprites[SPR2_FLY_].numframes, 2),
		7
	)
	local tailsOverlay, flipTailsOverlay = v.getSprite2Patch(
		"tails",
		SPR2_TAL7,
		false,
		frameByTime(leveltime, skins["tails"].sprites[SPR2_TAL7].numframes, 2),
		7
	)

	local characterX = 160 * FU + distance
	local character, flipCharacter = v.getSprite2Patch(
		player.skin,
		SPR2_RUN_,
		false,
		frameByTime(leveltime, skins[player.skin].sprites[SPR2_RUN_].numframes, 2),
		7
	)
	
	drawSprite(v, tailsX,     floorY + tailsY, drawScale, nil, tailsOverlay, V_SNAPTOBOTTOM, flipTailsOverlay, v.getColormap(TC_ALLWHITE, SKINCOLOR_WHITE))
	drawSprite(v, tailsX,     floorY + tailsY, drawScale, nil, tails,        V_SNAPTOBOTTOM, flipTails,        v.getColormap(TC_ALLWHITE, SKINCOLOR_WHITE))
	drawSprite(v, fangX,      floorY,          drawScale, nil, fang,         V_SNAPTOBOTTOM, flipFang,         v.getColormap(TC_ALLWHITE, SKINCOLOR_WHITE))
	drawSprite(v, characterX, floorY,          drawScale, nil, character,    V_SNAPTOBOTTOM, flipCharacter,    v.getColormap(TC_ALLWHITE, SKINCOLOR_WHITE))

	if progress < 10 then
		FH:drawPaletteRect(v, 0, 0, screenWidth, screenHeight, 0, V_SNAPTOTOP|V_SNAPTOLEFT|(V_10TRANS * progress))
	end
	if FHR.titleCardTime < 10 then
		FH:drawPaletteRect(v, 0, 0, screenWidth, screenHeight, 31, V_SNAPTOTOP|V_SNAPTOLEFT|(V_10TRANS * FHR.titleCardTime))
	end
end
return titleCardMenu, "titleCardMenu", 1, "global"
