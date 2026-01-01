local ui = {
	x = 16,
	y = 200 - 10 - 24,
	inside = 2 * FU,
	width = 60 * FU,
	height = 10 * FU,
	flags = V_SNAPTOLEFT|V_SNAPTOBOTTOM
}

function ui:draw(v, player, camera)
	if not player then return end
	if not player.heistRound then return end
	if not FH:isModifierActive(FH:getModifier("Air-borne")) then return end

	local x = self.x * FU
	local y = self.y * FU

	SSL.drawFixedString(v, x, y, FU, "STAY IN THE AIR!!", "TNYFN%03d", self.flags, 0, FU)
	FH:drawSTT(v, x, y - 10 * FU, FU, player.heistRound.groundedTime, self.flags, FU, FU)
end

return ui