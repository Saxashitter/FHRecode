local ui = {
	x = 16 + 70,
	y = 200 - 28,
	flags = V_SNAPTOLEFT|V_SNAPTOBOTTOM
}

--- @param v videolib
--- @param player player_t
function ui:draw(v, player)
	if not player.hg then return end

	local gametype = FH:isMode() --[[@as heistGametype_t]]

	if not gametype.teams then
		return
	end

	if FH:shouldShowJoinTeamUI(player) then
		SSL.drawString(v, self.x, self.y - 10, "[TOSS FLAG] Join Team", "TNYFN%03d", self.flags, 0, 0, V_YELLOWMAP)
		return
	end

	local iter = 1
	for k, member in ipairs(player.hg.team.players) do
		if member == player then continue end

		SSL.drawString(v, self.x, self.y - 10 * iter, member.name, "TNYFN%03d", self.flags, 0, 0, V_YELLOWMAP)
		iter = $ + 1
	end
end

return ui, "team", 1, "overlay"