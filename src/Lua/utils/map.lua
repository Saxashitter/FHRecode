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

--- Gets a variable from the passed map. If nil, uses the default one.
--- @param map number|nil
--- @param key string
--- @param default any|nil
function FH:getMapVariable(map, key, default)
	if map == nil then map = gamemap end

	if mapheaderinfo[map][key] ~= nil then
		if type(default) == "number" then
			return tonumber(mapheaderinfo[map][key]) 
		elseif type(default) == "boolean" then
			local var = mapheaderinfo[map][key]

			if var:lower() == "yes" or var:lower() == "true" or var:lower() == "on" or var:lower() == "enabled" then
				return true
			else
				return false
			end
		else
			return mapheaderinfo[map][key]
		end
	end

	return default
end
