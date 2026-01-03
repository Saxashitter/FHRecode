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

	local x = self.x * FU
	local y = self.y * FU
	local inside = self.inside
	local div = FixedDiv(player.heistRound.health, FH.characterHealths[skins[player.skin].name])

	FH:drawPaletteRect(v, x, y, self.width, self.height, 31, self.flags)
	if div then
		FH:drawPaletteRect(v, x + inside, y + inside, FixedMul(self.width - inside * 2, div), self.height - inside * 2, 112, self.flags)
	end
end

return ui, "health", 1, "overlay"