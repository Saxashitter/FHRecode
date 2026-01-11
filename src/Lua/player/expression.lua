--- @param player player_t
--- @param expression string
--- @param tics tic_t|nil
function FH:setPlayerExpression(player, expression, tics)
	-- TODO: effects per expression and stuff
	if tics == nil then tics = 0 end

	local sameExpression = expression == player.hr.expression

	if player.hr.expressionTics and not tics then
		player.hr.lastExpression = expression
		return
	end

	if not player.hr.expressionTics then
		player.hr.lastExpression = player.hr.expression
	end
	player.hr.expression = expression
	player.hr.expressionTics = tics

	if not sameExpression then
		player.hr.expressionScale = FU * 3 / 2
	end
end

--- @param player player_t
addHook("PlayerThink", function(player)
	local gametype = FH:isMode()

	if not gametype then return end
	if not player.hr then return end

	if player.hr.expressionTics then
		player.hr.expressionTics = $ - 1

		if player.hr.expressionTics == 0 then
			FH:setPlayerExpression(player, player.hr.lastExpression, 0)
		end
	end

	player.hr.expressionScale = ease.linear(FU / 2, $, FU)
end)