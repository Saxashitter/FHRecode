local preGameMenu = {}

preGameMenu.states = {
	character = dofile("hud/menus/pregame/character.lua"),
	waiting = dofile("hud/menus/pregame/waiting.lua")
}

--- @param v videolib
--- @param player player_t
--- @param camera camera_t
function preGameMenu:draw(v, player, camera)
	if FHR.currentState ~= "pregame" then return end

	local state = player.heistRound and player.heistRound.pregameState or "character"

	self.states[state](v, player, camera)

	local text = "Players ready:\n"

	local count = 0
	local readyCount = 0

	for player in players.iterate do
		if not player.heistRound then continue end

		count = $+1

		if player.heistRound.pregameState == "waiting" then
			readyCount = $+1
		end
	end

	text = $..readyCount.."/"..count
	FH:drawSTT(v, 12 * FU, 12 * FU, FU, FHR.pregameTimeLeft / TICRATE, V_SNAPTOLEFT|V_SNAPTOTOP, 0, 0)
	SSL.drawFixedString(v, 12 * FU + 18 * FU, 12 * FU, (FU/10) * 7, text, "STCFN%03d", V_SNAPTOTOP|V_SNAPTOLEFT, 0, 0)
end

return preGameMenu, "preGameMenu", 1, "global"