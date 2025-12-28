local timer = {}

--- @param v videolib
--- @param player player_t
--- @param camera camera_t
function timer:draw(v, player, camera)
	if FHR.currentState ~= "game" then return end
	if not FHR.escape then return end

	local t = FHR.escapeTime
	local tics = (t/35)/60
	local ringframe = ((((t/35) % 60) / 2)+1)

	if not t then
		ringframe = 0
	end

	local bg = v.cachePatch("FH_TMR_BG")
	local time = v.cachePatch("STTTIME")
	
	local x = ease.outexpo(FixedDiv(min(leveltime - FHR.escapeStartTime, 35), 35), 320 * FU, 320 * FU - bg.width * FU - 12 * FU)
	local y = 12 * FU

	v.drawScaled(x + bg.width * FU / 2 - time.width * FU / 2, y, FU, time, V_SNAPTORIGHT|V_SNAPTOTOP)

	y = $ + 12 * FU

	v.drawScaled(x, y, FU, bg, V_SNAPTORIGHT|V_SNAPTOTOP, v.getColormap(nil, SKINCOLOR_RED))

	if tics % 10 > 0 then
		local bar = v.cachePatch("FH_TMR_BAR" .. (tics % 10))

		v.drawScaled(x, y, FU, bar, V_SNAPTORIGHT|V_SNAPTOTOP, v.getColormap(nil, SKINCOLOR_RED))
	end

	if ringframe then
		local ring = v.cachePatch("FH_TMR_RING" .. ringframe)
		v.drawScaled(x, y + 5*FU, FU, ring, V_SNAPTORIGHT|V_SNAPTOTOP, v.getColormap(nil, player.skincolor))
	end

	y = $ + 43 * FU

	local string = ("%02d:%02d"):format(tics, (FHR.escapeTime / 35) % 60)
	local textX = x + bg.width * FU / 2 - ((8 * FU) * 5 / 2)

	for i = 1, #string do
		local char = string:sub(i, i)
		local patch

		if char == ":" then
			patch = v.cachePatch("STTCOLON")
		else
			patch = v.cachePatch("STTNUM"..char)
		end

		v.drawScaled(textX, y, FU, patch, V_SNAPTORIGHT|V_SNAPTOTOP)
		textX = $ + 8 * FU
	end
end

return timer, "escapeTimer", 1, "game"