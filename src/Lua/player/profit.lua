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

-- Manages how Profit is given
---@class heistProfitCVars_t
---@field ring consvar_t
---@field monitor consvar_t
---@field enemy consvar_t
---@field playerHurt consvar_t
---@field playerDeath consvar_t
---@field collectible consvar_t
---@field startedEscape consvar_t
---@field collectibleExt consvar_t

---@type heistProfitCVars_t
FH.profitCVars = {
	ring              = CV_RegisterVar{name = "fh_ringprofit",             defaultvalue = "8.25",   flags = CV_FLOAT|CV_NETVAR};
	monitor           = CV_RegisterVar{name = "fh_monitorprofit",          defaultvalue = "25.7",  flags = CV_FLOAT|CV_NETVAR};
	enemy             = CV_RegisterVar{name = "fh_enemyprofit",            defaultvalue = "50",  flags = CV_FLOAT|CV_NETVAR};
	playerHurt        = CV_RegisterVar{name = "fh_playerhurtprofit",       defaultvalue = "100.5", flags = CV_FLOAT|CV_NETVAR};
	playerDeath       = CV_RegisterVar{name = "fh_playerdeathprofit",      defaultvalue = "200.95", flags = CV_FLOAT|CV_NETVAR};
	collectible       = CV_RegisterVar{name = "fh_collectibleprofit",      defaultvalue = "350.8", flags = CV_FLOAT|CV_NETVAR};
	startedEscape     = CV_RegisterVar{name = "fh_escapeprofit",           defaultvalue = "500", flags = CV_FLOAT|CV_NETVAR};
	collectibleExt    = CV_RegisterVar{name = "fh_collectibleextraprofit", defaultvalue = "125.12", flags = CV_FLOAT|CV_NETVAR};
}

--- @param mobj mobj_t
--- @param var1 any
--- @param var2 any
function A_RingBox(mobj, var1, var2)
	super(mobj, var1, var2)

	if mobj.target and mobj.target.valid and mobj.target.player and mobj.target.player.heistRound then
		FH:addProfit(mobj.target.player, FH.profitCVars.ring.value * 10, "Destroyed Ring Box (10 Rings)")
	end
end

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
		-- heal hp

		FH:setHealth(source.player, min(FH.characterHealths[source.skin], source.player.heistRound.health + 15 * FU))
		return
	end

	if target.type == MT_PLAYER and target.player then
		FH:addProfit(source.player, FH.profitCVars.playerDeath.value, "Killed "..target.player.name)
		return
	end
end)