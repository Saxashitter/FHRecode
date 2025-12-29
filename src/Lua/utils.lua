--- Lua file for utility functions.

--- Gets the x, y, z and angle positions for the given mapthing_t
--- @param mapthing mapthing_t
--- @return fixed_t
--- @return fixed_t
--- @return fixed_t
--- @return angle_t
function FH:getMapthingWorldPosition(mapthing)
	if not mapthing then
		return 0, 0, 0, 0
	end

	local x = mapthing.x * FRACUNIT
	local y = mapthing.y * FRACUNIT

	local sector = R_PointInSubsector(x, y).sector
	local z = sector.floorheight + mapthing.z * FRACUNIT

	local angle = FixedAngle(mapthing.angle * FRACUNIT)

	return x, y, z, angle
end

--- Returns true if the button was just pressed for the player.
--- @param player player_t
--- @param button SINT8
--- @return boolean
function FH:isButtonPressed(player, button)
	return player.heistGlobal.buttons & button > 0 and player.heistGlobal.lastButtons & button == 0
end

--- Returns an x and y value depending on if the player is moving their directional inputs that way. Despite it's name, it's main use is for menus.
--- @param player player_t
--- @param leniency number
--- @return number
--- @return number
function FH:isMovePressed(player, leniency)
	return
		((abs(player.heistGlobal.sidemove) >= leniency and abs(player.heistGlobal.lastSidemove) < leniency) and 1 or 0) * max(-1, min(1, player.heistGlobal.sidemove)),
		((abs(player.heistGlobal.forwardmove) >= leniency and abs(player.heistGlobal.lastForwardmove) < leniency) and 1 or 0) * max(-1, min(1, player.heistGlobal.forwardmove))
end

--- Draws an background using the provided palette index.
--- @param v videolib
--- @param x fixed_t
--- @param y fixed_t
--- @param width fixed_t
--- @param height fixed_t
--- @param palette number
--- @param flags UINT32
function FH:drawPaletteRect(v, x, y, width, height, palette, flags)
	local patch = v.cachePatch(string.format("~%03d",palette))

	v.drawStretched(
		x, y,
		FixedDiv(width, patch.width*FU),
		FixedDiv(height, patch.height*FU),
		patch,
		flags or 0
	)
end

--- Get the player's portrait, useful for things like Intermission and Pre-Game, or maybe you wanna do something more than that? Do whatever you want.
--- @param v videolib
--- @param skin string|INT32
function FH:getCharPortrait(v, skin, colorable)
	--- @type skin_t
	local data = skins[skin]
	skin = data.name:upper()

	local name = "FH_PORTRAIT_"
	if colorable then
		name = "FH_PORTRAITC_"
	end

	if v.patchExists(name..skin) then
		return v.cachePatch(name..skin)
	end

	-- return the css portrait here
end

--- Draw numbers on the HUD using the STTNUM font.
--- @param v videolib
--- @param x fixed_t
--- @param y fixed_t
--- @param scale fixed_t
--- @param number number
--- @param flags UINT32|nil
--- @param align fixed_t|nil
--- @param valign fixed_t|nil
function FH:drawSTT(v, x, y, scale, number, flags, align, valign)
	if flags == nil then flags = 0 end
	if align == nil then align = 0 end
	if valign == nil then valign = 0 end

	local string = tostring(number)

	x = $ - FixedMul((8 * scale) * #string, align)
	y = $ - FixedMul((11 * scale) * #string, valign)

	for i = 1, #string do
		local patch = v.cachePatch("STTNUM"..string:sub(i, i))

		v.drawScaled(x, y, scale, patch, flags)
		x = $ + 8 * scale
	end
end

--- Changes the song used for the mod. Unlike S_ChangeMusic, this globally changes it, even for new players.
--- Set this to nil to revert to the map's default music.
--- TODO: Actually make this true using MusicChange and NetVars.
--- @param music string|nil
function FH:changeMusic(music)
	if music == nil then
		FHN.globalMusic = nil
		S_ChangeMusic(mapheaderinfo[gamemap].musname, true)
		return
	end

	FHN.globalMusic = music
	S_ChangeMusic(music, true)
end

--- Gets a variable from the passed map. If nil, uses the default one.
--- @param map number|nil
--- @param key string
--- @param default any|nil
function FH:getMapVariable(map, key, default)
	if map == nil then map = gamemap end

	if mapheaderinfo[map][key] then
		if type(default) == "number" and tonumber(mapheaderinfo[map][key]) ~= nil then
			return tonumber(mapheaderinfo[map][key]) 
		else
			return mapheaderinfo[map][key]
		end
	end

	return default
end