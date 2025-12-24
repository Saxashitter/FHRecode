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