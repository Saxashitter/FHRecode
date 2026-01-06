local rottenBoy = {}

--- @param v videolib
--- @param player player_t
--- @param camera camera_t
function rottenBoy:draw(v, player, camera)
	if FHR.currentState ~= "rottenboy" then return end

	v.drawFill()

	local sonic = v.cachePatch("FH_PORTRAIT_SONIC")

	v.drawStretched(160 * FU - sonic.width * FHR.rottenBoyXScale / 2, 100 * FU - sonic.height * FHR.rottenBoyYScale / 2, FHR.rottenBoyXScale, FHR.rottenBoyYScale, sonic)
end

return rottenBoy, "rottenBoyUngratefulBoy", 1, "menu"