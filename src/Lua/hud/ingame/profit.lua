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

	if player and player.heistGlobal then
		profit = player.heistGlobal.team.players[1].heistRound.profit
	end

	local stt = v.cachePatch("FH_PROFIT_STT")
	local dsign = v.cachePatch("FH_PROFIT_DSIGN")

	local stringWidth = (#string.format("%.2f", profit) + 1) * 8
	local profitX = max(self.x + stt.width + 2, self.profitX - stringWidth)

	v.draw(self.x, self.y, stt, self.flags)
	v.draw(profitX, self.y, dsign, self.flags)
	FH:drawDecimalSTT(v, (profitX + 8) * FU, self.y * FU, FU, profit, self.flags, 0, 0)

	local uis = player.heistRound.profitUI

	local count = #uis
	local latest = uis[count]

	-- collected effect
	for k, data in ipairs(uis) do
		local profitColor = data.profit > 0 and V_GREENMAP or V_REDMAP

		local t = FH:easeTime(data.time, data.animStart)
		local t2 = FH:easeTime(data.time, data.animFinish, data.animDuration - data.animFinish)

		local endX = (profitX + stringWidth + 2) * FU
		local startX = endX - 24 * FU

		local endY = -8 * FU
		local startY = self.y * FU

		local alpha = 10 - min(data.time, 10)
		if data.time >= data.animDuration - data.animFinish then
			alpha = min(data.time - (data.animDuration - 10), 10)
		end

		local x = ease.outback(t, startX, endX)
		local y = ease.incubic(t2, startY, endY)

		if k < count then
			local idx = count - k
			local push = -8 * FU

			-- push up based on how much anims there are
			local newStartY = push * (idx - 1)
			local newEndY = push * idx
			local newY = ease.outcubic(FH:easeTime(latest.time, latest.animStart), newStartY, newEndY)
	
			y = $ + newY
		end

		if alpha < 10 then
			local profit = data.profit
			SSL.drawFixedString(v, x, y, FU, string.format("%s $%.2f", profit > 0 and "+" or "-", abs(profit)), "STCFN%03d", self.flags|(V_10TRANS * alpha), 0, 0, profitColor, 0, 2 * FU)
		end
	end
end

return ui, "score", 1, "overlay"