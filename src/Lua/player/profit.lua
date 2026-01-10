--- Gives profit to the player and displays a cool visual on screen. If you don't wanna see any cool visuals, then just add onto heistPlayerRound_t.profit by yourself.
--- @param player player_t
--- @param profit fixed_t
--- @param tag string
--- @param division fixed_t|nil
function FH:addProfit(player, profit, tag, division)
	if division == nil then division = FU end
	local gametype = FH:isMode()
	if not gametype then return end

	-- divide profit based on division scale
	if division > 0 then
		local alivePlayers = 0

		for _, member in ipairs(player.heistGlobal.team.players) do
			if member.heistRound.escaped then continue end
			if member.heistRound.spectator then continue end

			alivePlayers = $ + 1
		end

		if alivePlayers > 0 then -- sanity check
			profit = FixedDiv(profit, division * alivePlayers)
		end
	end

	--- @type fixed_t
	local profitGainer = player.heistGlobal.team.players[1]
	profitGainer.heistRound.profit = $ + profit

	if profitGainer.heistRound.profit < 0 then
		profitGainer.heistRound.profit = 0
	end

	-- player.heistRound.profitUI = {
	-- 	lastTime = player.heistRound.profitUI.time,
	-- 	lastProfit = player.heistRound.profitUI.profit or 0,
	-- 	
	-- }

	-- local lastUI = player.heistRound.profitUI[#player.heistRound.profitUI]

	-- if lastUI and lastUI.time < lastUI.animDuration - lastUI.animFinish then
	-- 	lastUI.time = lastUI.animDuration - lastUI.animFinish
	-- end

	table.insert(player.heistRound.profitUI, {
		time = 0,
		profit = profit,
		tag = tag,
		animDuration = 2 * TICRATE,
		animStart = 20,
		animFinish = 10
	})
	gametype:addProfit(player, profit, tag)
	local found, _, value = FH:doesTableHave(player.heistRound.profitLog, function(log) return log.tag == tag end)

	if found then
		value.timesRan = $ + 1
		value.profit = $ + profit
		value.lastCollected = leveltime
		return
	end
	
	table.insert(player.heistRound.profitLog, {
		tag = tag,
		profit = profit,
		timesRan = 1,
		lastCollected = leveltime
	})
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
	monitor           = CV_RegisterVar{name = "fh_monitorprofit",          defaultvalue = "25.7",   flags = CV_FLOAT|CV_NETVAR};
	enemy             = CV_RegisterVar{name = "fh_enemyprofit",            defaultvalue = "50",     flags = CV_FLOAT|CV_NETVAR};
	playerHurt        = CV_RegisterVar{name = "fh_playerhurtprofit",       defaultvalue = "100.5",  flags = CV_FLOAT|CV_NETVAR};
	playerDeath       = CV_RegisterVar{name = "fh_playerdeathprofit",      defaultvalue = "200.95", flags = CV_FLOAT|CV_NETVAR};
	collectible       = CV_RegisterVar{name = "fh_collectibleprofit",      defaultvalue = "350.8",  flags = CV_FLOAT|CV_NETVAR};
	startedEscape     = CV_RegisterVar{name = "fh_escapeprofit",           defaultvalue = "500",    flags = CV_FLOAT|CV_NETVAR};
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

--- @param player player_t
addHook("PlayerThink", function(player)
	if not FH:isMode() then return end
	if not player.heistRound then return end

	for i = #player.heistRound.profitUI, 1, -1 do
		local ui = player.heistRound.profitUI[i]
		ui.time = $ + 1

		if ui.time == ui.animDuration then
			table.remove(player.heistRound.profitUI, i)
		end
	end
end)

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
		FH:setHealth(source.player, min(FH.characterHealths[source.skin], source.player.heistRound.health + 15 * FU))
		local overlay = P_SpawnMobjFromMobj(source, 0,0,0, MT_FH_OVERLAY) --[[@as heistOverlay_t]]
		overlay.target = source
		overlay.translation = "FH_AllGreen"
		overlay.alphaFuse = 15
		return
	end

	if target.type == MT_PLAYER and target.player then
		FH:addProfit(source.player, FH.profitCVars.playerDeath.value, "Killed "..target.player.name)
		return
	end
end)