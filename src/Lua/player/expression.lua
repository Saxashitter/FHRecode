--- @param player player_t
--- @param expression string
--- @param tics tic_t|nil
function FH:setPlayerExpression(player, expression, tics)
	-- TODO: effects per expression and stuff
	if tics == nil then tics = 0 end

	local sameExpression = expression == player.heistRound.expression

	if player.heistRound.expressionTics and not tics then
		player.heistRound.lastExpression = expression
		return
	end

	if not player.heistRound.expressionTics then
		player.heistRound.lastExpression = player.heistRound.expression
	end
	player.heistRound.expression = expression
	player.heistRound.expressionTics = tics

	if not sameExpression then
		player.heistRound.expressionScale = FU * 3 / 2
	end
end

--- @param player player_t
addHook("PlayerThink", function(player)
	local gametype = FH:isMode()

	if not gametype then return end
	if not player.heistRound then return end

	if player.heistRound.expressionTics then
		player.heistRound.expressionTics = $ - 1

		if player.heistRound.expressionTics == 0 then
			FH:setPlayerExpression(player, player.heistRound.lastExpression, 0)
		end
	end

	player.heistRound.expressionScale = ease.linear(FU / 2, $, FU)
end)