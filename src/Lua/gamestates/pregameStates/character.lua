local state = {}

local RIBBON_Y = 110
local RIBBON_HEIGHT = (9 * 2) + 2

local CHAR_NAME_Y = RIBBON_Y + 2
local SKIN_TOGGLE_Y = RIBBON_Y + RIBBON_HEIGHT - 2

local PORTRAIT_Y = 24
local PORTRAIT_SCALE = (FU / 5) * 3

local SWITCH_ANIM_DURATION = 25

FHN.bannedSkins = {}
COM_AddCommand("fh_banskin", function(player, skin)
	if not (skin and skins[skin]) then
		CONS_Printf(player, "Skin is not valid.")
		return
	end

	FHN.bannedSkins[skin] = not $

	if FHN.bannedSkins[skin] then
		print(skins[skin].realname.." has been banned from Fang's Heist!")
	else
		print(skins[skin].realname.." has been unbanned from Fang's Heist!")
	end
end, COM_ADMIN)

--- @param player player_t
local function getTic(player)
	return leveltime - player.hr.selectedSkinTime
end

function state:playerUpdate(gamestate, player)
	local x, _ = FH:isMovePressed(player, 50/4)
	local jump = FH:isButtonPressed(player, BT_JUMP)
	local spin = FH:isButtonPressed(player, BT_SPIN)

	if x ~= 0 then
		local newSkin = player.skin + x
		if newSkin < 0 then
			newSkin = #skins - 1
		end

		if newSkin > #skins - 1 then
			newSkin = 0
		end

		while not R_SkinUsable(player, newSkin)
		or FHN.bannedSkins[skins[newSkin].name] do
			newSkin = $ + x
			if newSkin < 0 then
				newSkin = #skins - 1
			end

			if newSkin > #skins - 1 then
				newSkin = 0
			end
		end

		player.hr.lastSkin = player.skin
		player.hr.lastSwap = x
		player.hr.selectedSkinTime = leveltime
		player.hr.useSuper = false

		S_StartSound(nil, sfx_kc39, player)
		R_SetPlayerSkin(player, newSkin)
	end

	if jump then
		return "menus"
	end

	if spin and FH.altSkins[skins[player.skin].name] then
		S_StartSound(nil, sfx_kc5e, player)
		player.hr.useSuper = not $
	end
end

--- @param v videolib
--- @param player player_t
function state:draw(gamestate, v, player)
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

	if player and player.hr.lastSkin ~= nil and getTic(player) < SWITCH_ANIM_DURATION then
		local dir = player.hr.lastSwap
		local t = ease.outcubic(FixedDiv(getTic(player), SWITCH_ANIM_DURATION), 0, 100 * FU) / 100 -- i dont feel like writing manual easing code give me a break

		portraitX = $ + FixedMul(screenWidth * dir, FU - t)

		local lastPortrait = FH:getCharPortrait(v, player.hr.lastSkin)
		local lastPortraitX = 160 * FU - lastPortrait.width * PORTRAIT_SCALE / 2
		lastPortraitX = $ + FixedMul(screenWidth * dir * -1, t)

		-- ease in new background
		if getTic(player) < 10 then
			FH.playerIconParallax:draw(v, skins[player.hr.lastSkin].name, leveltime, V_10TRANS * getTic(player))
		end

		v.drawScaled(lastPortraitX, PORTRAIT_Y * FU, PORTRAIT_SCALE, lastPortrait, 0)
	end

	v.drawScaled(portraitX, PORTRAIT_Y * FU, PORTRAIT_SCALE, portrait, 0)

	FH:drawPaletteRect(v, 0, RIBBON_Y * FU, v.width() * FU / v.dupx(), RIBBON_HEIGHT * FU, palette, V_SNAPTOLEFT)
	SSL.drawString(v, 160, CHAR_NAME_Y, skin.realname, "STCFN%03d", 0, FU/2, 0, textmap, 0, 0)
	if FH.altSkins[skin.name] then
		SSL.drawString(v, 160, SKIN_TOGGLE_Y, "[SPIN] Alt. Skin: "..FH:boolToString(player.hr.useSuper), "TNYFN%03d", 0, FU/2, FU, V_YELLOWMAP, 0, 0)
	end
	-- arrows
	v.drawScaled(160 * FU - stringWidth * FU / 2 - leftArrow.width * FU, CHAR_NAME_Y * FU, FU, leftArrow,  0, v.getStringColormap(V_YELLOWMAP))
	v.drawScaled(160 * FU + stringWidth * FU / 2,                        CHAR_NAME_Y * FU, FU, rightArrow, 0, v.getStringColormap(V_YELLOWMAP))

	SSL.drawFixedString(v, 12 * FU, (200 - 8 * 4) * FU, FU/2, "Work in progress.\n    "..string.char(30).." Stay tuned! This is a recode/rework of Fang's Heist!", "STCFN%03d", V_SNAPTOLEFT|V_SNAPTOBOTTOM)
end

return state