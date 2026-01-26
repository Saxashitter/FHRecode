local ui = {
	x = 160,
	y = 100,
	flags = 0,
	sparkles = {},
	duration = {}
}

local function createSparkle(self, v)
	local sparkle = {}

	sparkle = {
		x = v.RandomRange(0, v.width() * FU / v.dupx()),
		y = v.height() * FU / v.dupy() + 32 * FU,
		momy = 0
	}

	self.sparkles[#self.sparkles + 1] = sparkle
	return sparkle
end

--- @param v videolib
function ui:draw(v)
	if FHR.currentState ~= "game" then self.sparkles = {} return end

	local gametype = FH:isMode() --[[@as heistGametype_t]]
	if not gametype.isEscape then return end

	local string = (FHR.timesUpStart / TICRATE).." SECONDS\nREMAIN."

	if not FHR.escape then return end
	if FHR.escapeTime > FHR.timesUpStart then return end

	local progress = (FHR.timesUpStart - FHR.escapeTime)
	local alpha = max(0, min(progress - 5 * TICRATE, 10))

	if alpha < 10 then
		SSL.drawString(v, self.x, self.y, string, "STCFN%03d", V_ADD|(alpha * V_10TRANS), FU/2, FU/2, 0, FU/2)
	end

	createSparkle(self, v)

	for i = #self.sparkles, 1, -1 do
		local sparkle = self.sparkles[i]

		sparkle.momy = $ - FU / 3
		sparkle.y = $ + sparkle.momy

		if sparkle.y < 0 then
			table.remove(self.sparkles, i)
			continue
		end

		local sprite = v.getSpritePatch(SPR_SSPK, A, 0)

		v.drawScaled(sparkle.x, sparkle.y, FU / 4, sprite, V_SNAPTOLEFT|V_SNAPTOTOP|V_ADD|V_40TRANS)
	end

	if progress < 10 then
		FH:drawPaletteRect(v, 0, 0, v.width() * FU / v.dupx(), v.height() * FU / v.dupy(), 0, V_SNAPTOTOP|V_SNAPTOLEFT|(V_10TRANS * progress))
	end
end

return ui, "secondsLeft", 1, "overlay"