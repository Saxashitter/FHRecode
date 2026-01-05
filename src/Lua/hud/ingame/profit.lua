local ui = {
	x = 16,
	y = 12,
	profitX = 120,
	padding = 2,
	animDuration = 2 * TICRATE,
	animStart = 20,
	animFinish = 10,
	flags = V_SNAPTOLEFT|V_SNAPTOTOP
}

--- @param v videolib
--- @param player player_t
function ui:draw(v, player)
	local profit = 0

	if player and player.heistRound then
		profit = player.heistRound.profit
	end

	local stt = v.cachePatch("FH_PROFIT_STT")
	local dsign = v.cachePatch("FH_PROFIT_DSIGN")

	local stringWidth = (#string.format("%.2f", profit) + 1) * 8
	local profitX = max(self.x + stt.width + 2, self.profitX - stringWidth)

	v.draw(self.x, self.y, stt, self.flags)
	v.draw(profitX, self.y, dsign, self.flags)
	FH:drawDecimalSTT(v, (profitX + 8) * FU, self.y * FU, FU, profit, self.flags, 0, 0)

	-- collected effect
	
	if player.heistRound.profitUI.time == -1 then return end
	
	local progress = leveltime - player.heistRound.profitUI.time
	
	if progress > self.animDuration then return end
	local profitColor = player.heistRound.profitUI.profit > 0 and V_GREENMAP or V_REDMAP

	local t = FH:easeTime(progress, self.animStart)
	local t2 = FH:easeTime(progress, self.animFinish, self.animDuration - self.animFinish)

	local endX = (profitX + stringWidth + 2) * FU
	local startX = endX - 24 * FU

	local endY = -8 * FU
	local startY = self.y * FU

	local alpha = 10 - min(progress, 10)
	if progress >= self.animDuration - self.animFinish then
		alpha = min(progress - (self.animDuration - 10), 10)
	end

	local x = ease.outback(t, startX, endX)
	local y = ease.incubic(t2, startY, endY)

	if alpha < 10 then
		local profit = player.heistRound.profitUI.profit
		SSL.drawFixedString(v, x, y, FU, string.format("%s $%.2f", profit > 0 and "+" or "-", abs(profit)), "STCFN%03d", self.flags|(V_10TRANS * alpha), 0, 0, profitColor, 0, 2 * FU)
	end
end

return ui, "score", 1, "overlay"