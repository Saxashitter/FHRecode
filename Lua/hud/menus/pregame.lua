local preGameMenu = {}

preGameMenu.states = {
	character = dofile("hud/menus/pregame/character.lua"),
	team = dofile("hud/menus/pregame/team.lua"),
	waiting = dofile("hud/menus/pregame/waiting.lua")
}

--- @param v videolib
--- @param player player_t
--- @param camera camera_t
function preGameMenu:draw(v, player, camera)
	if FHR.currentState ~= "pregame" then return end

	local state = player.heistRound and player.heistRound.pregameState or "character"

	self.states[state](v, player, camera)
end

return preGameMenu, "preGameMenu", 1, "global"