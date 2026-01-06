local timer = {}

--- @param v videolib
--- @param player player_t
--- @param camera camera_t
function timer:draw(v, player, camera)
	local gametype = FH:isMode()
	if not gametype then return end

	if FHR.currentState ~= "game" then return end
	if not FHR.escape then return end

	local escapeTime = FHR.escapeTime

	if escapeTime <= gametype.timesUpStart then
		return
	end

	-- Tween timing
	local easeInTics = TICRATE
	local easeOutTics = TICRATE

	-- Time
	local seconds   = escapeTime / 35
	local minutes   = seconds / 60
	local ringFrame = ((seconds % 60) / 2) + 1

	-- Patches
	local bgPatch   = v.cachePatch("FH_TMR_BG")
	local timePatch = v.cachePatch("STTTIME")

	-- Position
	local x = ease.outexpo(
		FixedDiv(min(leveltime - FHR.escapeStartTime, easeInTics), easeInTics),
		320 * FU,
		320 * FU - bgPatch.width * FU - 12 * FU
	)
	local y = 12 * FU

	local length = TICRATE
	if escapeTime <= gametype.timesUpStart + length then
		local progress = escapeTime
		y = ease.inback(
			FixedDiv(escapeTime)
		)
	end

	-- "TIME" label
	v.drawScaled(
		x + bgPatch.width * FU / 2 - timePatch.width * FU / 2,
		y,
		FU,
		timePatch,
		V_SNAPTORIGHT|V_SNAPTOTOP
	)

	y = $ + 12 * FU

	-- Background bar
	v.drawScaled(
		x,
		y,
		FU,
		bgPatch,
		V_SNAPTORIGHT|V_SNAPTOTOP,
		v.getColormap(nil, SKINCOLOR_RED)
	)

	-- Progress bar (0–9)
	local barIndex = minutes % 10
	if barIndex > 0 then
		local barPatch = v.cachePatch("FH_TMR_BAR" .. barIndex)
		v.drawScaled(
			x,
			y,
			FU,
			barPatch,
			V_SNAPTORIGHT|V_SNAPTOTOP,
			v.getColormap(nil, SKINCOLOR_RED)
		)
	end

	-- Ring indicator
	if seconds then
		local ringPatch = v.cachePatch("FH_TMR_RING" .. ringFrame)
		v.drawScaled(
			x,
			y + 5 * FU,
			FU,
			ringPatch,
			V_SNAPTORIGHT|V_SNAPTOTOP,
			v.getColormap(nil, player.skincolor)
		)
	end

	y = $ + 43 * FU

	-- Digital time text
	local timeString = ("%02d:%02d"):format(minutes, seconds % 60)
	local textX = x + bgPatch.width * FU / 2 - (8 * FU * 5 / 2)

	for i = 1, #timeString do
		local char = timeString:sub(i, i)
		local digitPatch = (char == ":")
			and v.cachePatch("STTCOLON")
			or  v.cachePatch("STTNUM" .. char)

		v.drawScaled(
			textX,
			y,
			FU,
			digitPatch,
			V_SNAPTORIGHT|V_SNAPTOTOP
		)

		textX = $ + 8 * FU
	end
end

return timer, "escapeTimer", 1, "overlay"