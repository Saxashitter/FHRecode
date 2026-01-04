local ui = {
	x = 16,
	y = 12,
	profitX = 120,
	padding = 2,
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

	local stringWidth = (#FH:getDecimalNumber(profit) + 1) * 8
	local profitX = max(self.x + stt.width + 2, self.profitX - stringWidth)

	v.draw(self.x, self.y, stt, self.flags)
	v.draw(profitX, self.y, dsign, self.flags)
	FH:drawDecimalSTT(v, (profitX + 8) * FU, self.y * FU, FU, profit, self.flags, 0, 0)
end

return ui, "score", 1, "overlay"