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

	return v.getSprite2Patch(data.name, SPR2_XTRA, false, B, 0)
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

	local str = string.format("%.2f", number)

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