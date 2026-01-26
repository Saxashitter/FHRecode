local battle = _FH_BATTLE

function battle:playerInit(player, currentState)
	player.hr.qualified = true

	if currentState == "game" then
		player.hr.spectator = true
		player.hr.qualified = false

		player.spectator = true
	end
end

function battle:eliminate(player)
	if player.mo and player.mo.valid and player.mo.health then
		P_DamageMobj(player.mo, nil, nil, 999, DMG_INSTAKILL)
	end
	chatprint("* "..player.name.." has been eliminated!")

	player.hr.qualified = false
	player.hr.spectator = true

	self:safeFinish()
end

function battle:getWorstPlayer()
	local worstPlayer
	local profit = INT32_MAX

	for player in players.iterate do
		if not player.hr then continue end
		if not player.hr.qualified then continue end
		if player.hr.spectator then continue end

		if player.hr.profit < profit then
			profit = player.hr.profit
			worstPlayer = player
		end
	end

	return worstPlayer
end

function battle:playerQuit(player, currentState)
	if currentState ~= "game" then return end

	if player.hr.qualified then
		self:eliminate(player)
	end
end

function battle:playerDeath(player, currentState)
	if currentState ~= "game" then return end
	if not FHR.showdown then return end

	if player.hr.qualified then
		self:eliminate(player)
	end
end