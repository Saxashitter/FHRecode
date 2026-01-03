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
	y = $ - FixedMul(11 * scale, valign)

	for i = 1, #string do
		local patch = v.cachePatch("STTNUM"..string:sub(i, i))

		v.drawScaled(x, y, scale, patch, flags)
		x = $ + 8 * scale
	end
end

--- Draw numbers on the HUD using the STTNUM font, with decimals
--- @param v videolib
--- @param x fixed_t
--- @param y fixed_t
--- @param scale fixed_t
--- @param number fixed_t
--- @param flags UINT32|nil
--- @param align fixed_t|nil
--- @param valign fixed_t|nil
function FH:drawDecimalSTT(v, x, y, scale, number, flags, align, valign)
	flags  = flags  or 0
	align  = align  or 0
	valign = valign or 0

	-- Extract integer + fractional parts
	local intpart = number / FRACUNIT
	local frac = abs(number % FRACUNIT)

	-- Limit to 2 decimal places
	local frac2 = (frac * 100) / FRACUNIT

	-- Build string
	local str
	if frac2 > 0 then
		str = string.format("%d.%02d", intpart, frac2)
	else
		str = tostring(intpart)
	end

	-- Alignment
	local charw = 8 * scale
	local totalw = charw * #str

	x = $ - FixedMul(totalw, align)
	y = $ - FixedMul(11 * scale, valign)

	-- Draw
	for i = 1, #str do
		local c = str:sub(i, i)
		local patch

		if c == "." then
			patch = v.cachePatch("STTPERIO")
		else
			patch = v.cachePatch("STTNUM"..c)
		end

		v.drawScaled(x, y, scale, patch, flags)
		x = $ + charw
	end
end


--- Changes the song used for the mod. Unlike S_ChangeMusic, this globally changes it, even for new players.
--- Set this to nil to revert to the map's default music.
--- @param music string|nil
function FH:changeMusic(music, loop)
	if loop == nil then loop = true end
	if music == nil then
		FHN.globalMusic = nil
		S_ChangeMusic(mapheaderinfo[gamemap].musname, loop)
		return
	end

	FHN.globalMusic = music
	S_ChangeMusic(music, loop)
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

--- Moves 'current' toward 'target' by at most 'step'
--- @param current number
--- @param target number
--- @param step number
function FH:approach(current, target, step)
    if current < target then
        current = current + step

        if current > target then
            current = target
        end

    elseif current > target then
        current = current - step

        if current < target then
            current = target
        end
    end

    return current
end

--- @param target mobj_t
--- @param point table
--- @param minSpeed fixed_t|nil
function FH:knockbackMobj(target, point, minSpeed)
	local tz = target.z + target.height / 2
	local pz = point.z + point.height / 2
	local speed = max(R_PointToDist2(0, 0, R_PointToDist2(0, 0, target.momx, target.momy), target.momz), minSpeed or 0)
	local dist = R_PointToDist2(target.x, target.y, point.x, point.y)
	local angle = R_PointToAngle2(target.x, target.y, point.x, point.y)
	local aiming = R_PointToAngle2(0, 0, dist, pz - tz)

	P_InstaThrust(target, angle, -FixedMul(speed, cos(aiming)))
	---@diagnostic disable-next-line: assign-type-mismatch
	target.momz = -FixedMul(speed, sin(aiming))
end

--- Reflects target momentum off a point (shield-style)
--- @param target mobj_t
--- @param point table {x,y,z}
--- @param speedScale fixed_t|nil
function FH:reflectMobj(target, point, speedScale)
	speedScale = speedScale or FRACUNIT

	-- Incoming velocity
	local vx, vy, vz = target.momx, target.momy, target.momz

	-- Normal direction (from point to target)
	local nx = target.x - point.x
	local ny = target.y - point.y
	local nz = target.z + target.height / 2 - point.z + (point.height or 0) / 2

	local nlen = R_PointToDist2(0, 0, R_PointToDist2(0, 0, nx, ny), nz)
	if nlen == 0 then return end

	-- Normalize normal
	nx = FixedDiv(nx, nlen)
	ny = FixedDiv(ny, nlen)
	nz = FixedDiv(nz, nlen)

	-- Dot product
	local dot =
		FixedMul(vx, nx) +
		FixedMul(vy, ny) +
		FixedMul(vz, nz)

	-- Reflection
	target.momx = FixedMul(vx - FixedMul(2*dot, nx), speedScale)
	target.momy = FixedMul(vy - FixedMul(2*dot, ny), speedScale)
	target.momz = FixedMul(vz - FixedMul(2*dot, nz), speedScale)
end

--- Normalized time value from 0 to FRACUNIT
--- @param tics tic_t
--- @param duration tic_t
--- @param delay tic_t|nil
--- @return fixed_t
function FH:easeTime(tics, duration, delay)
	delay = delay or 0

	if duration <= 0 then
		return FRACUNIT
	end

	local t = tics - delay
	if t <= 0 then
		return 0
	end

	if t >= duration then
		return FRACUNIT
	end

	return FixedDiv(t, duration)
end

--- Returns randomized items from a table.
--- @param tbl table
--- @param amount number
--- @return table
function FH:randomItems(tbl, amount)
	local new = {}
	local selected = {}

	if #tbl == 0 then
		return selected
	end

	for i = 1, #tbl do
		new[i] = tbl[i]
	end

	for i = 1, amount do
		local item = P_RandomRange(1, #new)

		table.insert(selected, new[item])
		table.remove(new, item)

		if #new == 0 then break end
	end

	return selected
end

--- Gets a fixed random number from range.
--- @param start fixed_t
--- @param finish fixed_t
--- @return fixed_t
function FH:fixedRandom(start, finish)
	if start > finish then
		start, finish = finish, start
	end

	local range = finish - start
	return start + FixedMul(range, P_RandomFixed())
end
