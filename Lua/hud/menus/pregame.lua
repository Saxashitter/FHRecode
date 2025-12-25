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

	FH.playerIconParallax:draw(v, skins[player and player.skin or 0].name, leveltime)

	v.drawString(160, 100, "W.I.P", V_ALLOWLOWERCASE, "center")
end

return preGameMenu, "pregameMenu", 1, "global"