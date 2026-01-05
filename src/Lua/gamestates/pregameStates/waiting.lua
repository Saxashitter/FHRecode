local state = {}

function state:enter(gamestate, player)
	if gamestate:canSwitch() then
		gamestate:switch()
		return
	end

	S_StartSound(nil, sfx_kc5e, player)
end

function state:playerUpdate(gamestate, player)
	if FH:isButtonPressed(player, BT_SPIN) then
		-- to character state you go
		return "character"
	end
end

--- @param v videolib
--- @param player player_t
function state:draw(gamestate, v, player)
	FH.playerIconParallax:draw(v, skins[player and player.skin or 0].name, leveltime)

	SSL.drawString(v, 160, 100, "Waiting...", "STCFN%03d", 0, FU/2, FU/2, nil, nil, nil)
end

return state