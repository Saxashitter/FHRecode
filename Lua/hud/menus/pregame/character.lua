local RIBBON_Y = 110
local RIBBON_HEIGHT = 20

local CHAR_NAME_Y = RIBBON_Y + RIBBON_HEIGHT / 2

local PORTRAIT_Y = 24
local PORTRAIT_SCALE = (FU / 5) * 3

local SWITCH_ANIM_DURATION = 25

--- @param player player_t
local function getTic(player)
	return leveltime - player.heistRound.selectedSkinTime
end

--- @param v videolib
--- @param player player_t
return function(v, player)
	FH.playerIconParallax:draw(v, skins[player and player.skin or 0].name, leveltime)

	local screenWidth = v.width() * FU / v.dupx()
	local screenHeight = v.height() * FU / v.dupy()

	local skin = skins[player and player.skin or 0]
	local color = skincolors[skin.prefcolor]
	local inverseColor = skincolors[color.invcolor]
	local palette = inverseColor.ramp[7]
	local textmap = color.chatcolor

	local stringWidth = SSL.getStringWidth(v, skin.realname, "STCFN%03d")

	local leftArrow = v.cachePatch("STCFN028")
	local rightArrow = v.cachePatch("STCFN029")

	-- portrait
	local portrait = FH:getCharPortrait(v, player and player.skin or 0)
	local portraitX = 160 * FU - portrait.width * PORTRAIT_SCALE / 2

	if player and player.heistRound.lastSkin ~= nil and getTic(player) < SWITCH_ANIM_DURATION then
		local dir = player.heistRound.lastSwap
		local t = ease.outcubic(FixedDiv(getTic(player), SWITCH_ANIM_DURATION), 0, 100 * FU) / 100 -- i dont feel like writing manual easing code give me a break

		portraitX = $ + FixedMul(screenWidth * dir, FU - t)

		local lastPortrait = FH:getCharPortrait(v, player.heistRound.lastSkin)
		local lastPortraitX = 160 * FU - lastPortrait.width * PORTRAIT_SCALE / 2
		lastPortraitX = $ + FixedMul(screenWidth * dir * -1, t)

		-- ease in new background
		if getTic(player) < 10 then
			FH.playerIconParallax:draw(v, skins[player.heistRound.lastSkin].name, leveltime, V_10TRANS * getTic(player))
		end

		v.drawScaled(lastPortraitX, PORTRAIT_Y * FU, PORTRAIT_SCALE, lastPortrait, 0)
	end

	v.drawScaled(portraitX, PORTRAIT_Y * FU, PORTRAIT_SCALE, portrait, 0)

	FH:drawPaletteRect(v, 0, RIBBON_Y * FU, v.width() * FU / v.dupx(), RIBBON_HEIGHT * FU, palette, V_SNAPTOLEFT)
	SSL.drawString(v, 160, CHAR_NAME_Y, skin.realname, "STCFN%03d", 0, FU/2, FU/2, textmap, 0, 0)

	-- arrows
	v.drawScaled(160 * FU - stringWidth * FU / 2 - leftArrow.width * FU, RIBBON_Y * FU + RIBBON_HEIGHT * FU / 2 - SSL.getFont("STCFN%03d").height * FU / 2, FU, leftArrow,  0, v.getStringColormap(V_YELLOWMAP))
	v.drawScaled(160 * FU + stringWidth * FU / 2,                        RIBBON_Y * FU + RIBBON_HEIGHT * FU / 2 - SSL.getFont("STCFN%03d").height * FU / 2, FU, rightArrow, 0, v.getStringColormap(V_YELLOWMAP))

	SSL.drawFixedString(v, 12 * FU, (200 - 8 * 4) * FU, FU/2, "Work in progress.\n    "..string.char(30).." Stay tuned! This is a recode/rework of Fang's Heist!", "STCFN%03d", V_SNAPTOLEFT|V_SNAPTOBOTTOM)
end