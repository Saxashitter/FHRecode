local ui = {}

--- @param v videolib
--- @param player player_t
--- @param camera camera_t
function ui:draw(v, player, camera)
	if not FH:isModifierActive(FH:getModifier("top cinco jumpscares")) then return end
	if FHR.foxyJumpscareTime == -1 then return end

	local frame = (leveltime - FHR.foxyJumpscareTime) / 4
	if frame > 13 then return end

	local screenWidth = v.width() / v.dupx()
	local screenHeight = v.height() / v.dupy()

	local patch = v.cachePatch("FH_FOXY_JUMPSCARE"..frame)

	local scale = max(FixedDiv(screenWidth, patch.width), FixedDiv(screenHeight, patch.height))

	v.drawScaled(160 * FU - patch.width * scale / 2, 100 * FU - patch.height * scale / 2, scale, patch)
end

return ui, "jumpscare", 2, "overlay"