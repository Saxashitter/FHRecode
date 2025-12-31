local intermissionMenu = {}

local states = {
	game = dofile("hud/menus/intermission/game.lua"),
	results = dofile("hud/menus/intermission/results.lua")
}

--- @param v videolib
--- @param player player_t
--- @param camera camera_t
function intermissionMenu:draw(v, player, camera)
	if FHR.currentState ~= "intermission" then return end

	-- local winnerText = "The winner is..."

	-- if FHR.winningPlayer then
	-- 	winnerText = $.."\n"..FHR.winningPlayer.name
	-- 	winnerText = $.."\n".."Profit: "..string.format("%.2f", FHR.winningPlayer.profit)
	-- else
	-- 	winnerText = $.."\n".."Nobody..."
	-- end

	-- FH.playerIconParallax:draw(v, skins[player and player.skin or 0].name, leveltime)

	-- SSL.drawFixedString(v, 160*FU, 100*FU, FU, winnerText, "STCFN%03d", 0, FU/2, FU/2, 0, 0, 2 * FU)

	local tics = leveltime - FHR.intermissionStartTime
	local gamestate = FH.gamestates[FHR.currentState]
	local state = "game"

	if tics >= gamestate.gameScreenEnd then
		state = "intermission"
	end

	states[state](v, player, camera)

	-- FH.playerIconParallax:draw(v, skins[player and player.skin or 0].name, leveltime)
	-- SSL.drawString(v, 160, 100, "W.I.P", "STCFN%03d", 0, FU/2, FU/2)
end

return intermissionMenu, "intermissionMenu", 1, "global"