--- Gives profit to the player and displays a cool visual on screen. If you don't wanna see any cool visuals, then just add onto heistPlayerRound_t.profit by yourself.
--- @param player player_t
--- @param profit fixed_t
--- @param tag string
function FH:addProfit(player, profit, tag)
	--- @type fixed_t
	player.heistRound.profit = $ + profit

	if player.heistRound.profit < 0 then
		player.heistRound.profit = 0
	end
end

-- Manage how Profit is given.
FH.profitCVars = {
	--- @type consvar_t
	ring = CV_RegisterVar{name = "fh_ringprofit", defaultvalue = "8", flags = CV_FLOAT|CV_NETVAR};
	monitor = CV_RegisterVar{name = "fh_monitorprofit", defaultvalue = "25", flags = CV_FLOAT|CV_NETVAR};
	enemy = CV_RegisterVar{name = "fh_enemyprofit", defaultvalue = "50", flags = CV_FLOAT|CV_NETVAR};
	playerHurt = CV_RegisterVar{name = "fh_playerhurtprofit", defaultvalue = "100", flags = CV_FLOAT|CV_NETVAR};
	playerDeath = CV_RegisterVar{name = "fh_playerdeathprofit", defaultvalue = "200", flags = CV_FLOAT|CV_NETVAR};
	startedEscape = CV_RegisterVar{name = "fh_escapeprofit", defaultvalue = "500", flags = CV_FLOAT|CV_NETVAR};
}

--- @param target mobj_t
--- @param source mobj_t
addHook("MobjDeath", function(target, _, source)
	if not FH:isMode() then return end
	if not target.valid then return end
	if not source then return end
	if not source.valid then return end
	if source.type ~= MT_PLAYER then return end
	if not source.player then return end
	if not source.player.heistRound then return end
	
	if target.type == MT_RING then
		FH:addProfit(source.player, FH.profitCVars.ring.value, "Collected Ring")
		return
	end

	if target.flags & MF_ENEMY > 0 then
		FH:addProfit(source.player, FH.profitCVars.enemy.value, "Destroyed Badnik")
		return
	end

	if target.flags & MF_MONITOR > 0 then
		FH:addProfit(source.player, FH.profitCVars.monitor.value, "Destroyed Monitor")
		return
	end

	if target.type == MT_PLAYER and target.player then
		FH:addProfit(source.player, FH.profitCVars.playerDeath.value, "Killed "..target.player.name)
		return
	end
end)