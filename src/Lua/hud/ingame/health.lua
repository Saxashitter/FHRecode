local ui = {
	x = 16 * FU,
	y = 176 * FU,
	inside = FU,
	width = 60 * FU,
	height = 7 * FU,
	offsetY = 9 * FU,
	flags = V_SNAPTOLEFT|V_SNAPTOBOTTOM
}

function ui:draw(v, player, camera)
	if not player then return end
	if not player.heistRound then return end

	local x = self.x
	local y = self.y
	local inside = self.inside
	local div = FixedDiv(player.heistRound.health, FH.characterHealths[skins[player.skin].name])

	local life = v.getSprite2Patch(player.skin, SPR2_XTRA, false, A, 0)
	local blockBar = v.cachePatch("FH_BLOCKBAR")
	local blockBarFill = v.cachePatch("FH_BLOCKBAR_FILL")
	local stringWidth = SSL.getStringWidth(v, player.name:upper(), "STCFN%03d")
	
	-- treasures
	local tresX = x + life.width * (FU / 2) / 2
	local tresY = y

	for _, col in ipairs(player.heistRound.collectibles) do
		if not col.valid then continue end

		local sprite = v.getSpritePatch(col.sprite, col.frame & FF_FRAMEMASK, 0)

		v.drawScaled(tresX, tresY, FU / 2, sprite, self.flags)
		tresY = $ - 12 * FU
	end

	-- life icon
	v.drawScaled(x, y, FU / 2, life, self.flags, v.getColormap(skins[player.skin].name, player.skincolor))

	x = $ + life.width * FU / 2 + FU * 2
	-- block bar
	local blockDiv = FixedDiv(player.heistRound.blockStrength, FU) -- 0..FU
	blockDiv = min(FU, max(0, blockDiv)) -- clamp for safety
	
	v.drawScaled(x, y, FU, blockBar, self.flags)

	if blockDiv then
		local fillHeight = FixedMul(blockBarFill.height*FU, blockDiv)
		local cropY = blockBarFill.height*FU - fillHeight
		
		v.drawCropped(
			x + FU,
			y + FU + cropY,
			FU,
			FU,
			blockBarFill,
			self.flags,
			nil,
			0,
			cropY,
			blockBarFill.height*FU,
			fillHeight
		)
	end
	x = $ + blockBar.width*FU + FU * 2

	-- name
	SSL.drawFixedString(v, x, y, FU, player.name:upper(), "STCFN%03d", self.flags, 0, 0, V_YELLOWMAP, 0, 0)
	y = $ + self.offsetY

	-- health
	FH:drawPaletteRect(v, x, y, self.width, self.height, 31, self.flags)
	if div then
		FH:drawPaletteRect(v, x + inside, y + inside, FixedMul(self.width - inside * 2, div), self.height - inside * 2, 112, self.flags)
	end
end

return ui, "lives", 1, "overlay"