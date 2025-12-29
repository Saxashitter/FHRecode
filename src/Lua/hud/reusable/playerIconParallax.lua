local playerIconParallax = {}

playerIconParallax.loopTics = 32

--- @param v videolib
function playerIconParallax:draw(v, skin, tics, flags)
	--- @type fixed_t
	local t = FixedDiv(tics, self.loopTics)

	local graphicName = "FH_PREGAME_"..(skin:upper())
	local graphic

	if v.patchExists(graphicName) then
		graphic = v.cachePatch(graphicName)
	else
		graphic = v.cachePatch("FH_PREGAME_UNKNOWN")
	end

	local sw = v.width() * FU / v.dupx()
	local sh = v.height() * FU / v.dupy()

	local pw = graphic.width * FU
	local ph = graphic.height * FU

	--- Parallax offset (wrapped)
	local ox = -((16 * t) % pw)
	local oy = -((16 * t) % ph)

	--- Draw tiles to cover the screen
	--- @type fixed_t
	for x = ox - pw, sw + pw, pw do
		--- @type fixed_t
		for y = oy - ph, sh + ph, ph do
			v.drawScaled(x, y, FU, graphic, V_SNAPTOLEFT|V_SNAPTOTOP|(flags or 0))
		end
	end
end

return playerIconParallax