local ui = {
	x = 16 * FU,
	y = (200 - 12 - 63) * FU,
	inside = FU,
	width = 60 * FU,
	height = 7 * FU,
	offsetY = 9 * FU,
	flags = V_SNAPTOLEFT|V_SNAPTOBOTTOM
}

--- @param v videolib
--- @param player player_t
--- @return patch_t|false
function ui:getExpression(v, player)
	if not (player and player.hr) then return false end

	local skin = skins[player.skin]
	local skinName = (skin and skin.name or "sonic"):upper()

	local expression = player.hr.expression
	if not expression then return false end
	expression = expression:upper()

	local graphics = {
		"FH_MONITOR_"..skinName.."_"..expression,
		"FH_MONITOR_"..skinName.."_DEFAULT",
		"FH_MONITOR_SONIC_"..expression,
		"FH_MONITOR_SONIC_DEFAULT"
	}

	for k, graphicName in ipairs(graphics) do
		if v.patchExists(graphicName) then
			return v.cachePatch(graphicName)
		end
	end

	return false
end

--- @param v videolib
--- @param player player_t
--- @param camera camera_t
function ui:draw(v, player, camera)
	if not player then return end
	if not player.hr then return end

	local x = self.x
	local y = self.y
	local inside = self.inside
	local div = FixedDiv(player.hr.health, FH.characterHealths[skins[player.skin].name])

	local charExpression = self:getExpression(v, player)
	local blockBar = v.cachePatch("FH_BLOCKBAR")
	local blockBarFill = v.cachePatch("FH_BLOCKBAR_FILL")
	
	if charExpression then
		local es = player.hr.expressionScale

		v.drawScaled(x, y + 63 * FU, es, charExpression, self.flags, v.getColormap(player.skin, player.skincolor))
	else
		-- TODO: life icon fallback
	end
	x = $ + 70 * FU
	y = $ + 63 * FU - 16 * FU

	-- block bar
	local blockDiv = FixedDiv(player.hr.blockStrength, FU) -- 0..FU
	---@diagnostic disable-next-line: cast-local-type
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
	SSL.drawFixedString(v, x, y, FU, player.name:upper(), "TNYFN%03d", self.flags, 0, 0, V_YELLOWMAP, 0, 0)
	y = $ + self.offsetY

	-- health
	FH:drawPaletteRect(v, x, y, self.width, self.height, 31, self.flags)
	if div then
		FH:drawPaletteRect(v, x + inside, y + inside, FixedMul(self.width - inside * 2, div), self.height - inside * 2, 112, self.flags)
	end
end

return ui, "lives", 1, "overlay"