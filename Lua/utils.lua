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