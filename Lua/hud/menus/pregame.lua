local preGameMenu = {}

preGameMenu.states = {
	character = dofile("hud/menus/pregame/character.lua"),
	team = dofile("hud/menus/pregame/team.lua"),
	waiting = dofile("hud/menus/pregame/waiting.lua")
}

--- @param v videolib
--- @param skin string
function preGameMenu:getPortrait(v, skin, color)
	--- @type skin_t
	local data = skins[skin]
	skin = data.name:upper()

	local name = "FH_PORTRAIT_"
	if color then
		name = "FH_PORTRAITC_"
	end

	if v.patchExists(name..skin) then
		return v.cachePatch(name..skin)
	end

	-- return the css portrait here
end

--- @param v videolib
--- @param player player_t
--- @param camera camera_t
function preGameMenu:draw(v, player, camera)
	if FHR.currentState ~= "pregame" then return end

	local state = player.heistRound and player.heistRound.pregameState or "character"

	FH.playerIconParallax:draw(v, skins[player and player.skin or 0].name, leveltime)

	self.states[state](v, player, camera)

	v.drawString(160, 100, "W.I.P", V_ALLOWLOWERCASE, "center")
end

return preGameMenu, "preGameMenu", 1, "global"