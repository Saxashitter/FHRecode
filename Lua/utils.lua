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