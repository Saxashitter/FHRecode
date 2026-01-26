local battle = _FH_BATTLE

battle.signpostThing = 501
battle.ringThing = 1
battle.timesUpStart = 22591 * TICRATE / MUSICRATE
battle.freeTimeTics = 20 * TICRATE
battle.ticsUntilDeath = 15 * TICRATE

--- @param map number
function battle:init(map)
	FHR.freeTimeTics = self.freeTimeTics
	FHR.ticsUntilDeath = self.ticsUntilDeath
	FHR.showdown = false
end

--- @param currentState string
function battle:update(currentState)
	if currentState ~= "game" then return end

	if not FHR.gameCountdown and FHR.freeTimeTics then
		FHR.freeTimeTics = $ - 1
	end

	if not FHR.freeTimeTics and not FHR.showdown then
		FHR.ticsUntilDeath = $ - 1

		if not FHR.ticsUntilDeath then
			FHR.ticsUntilDeath = self.ticsUntilDeath

			local player = self:getWorstPlayer()

			if player then
				self:eliminate(player)
			end
		end
	end

	-- FHR.battleTime = $ - 1

	-- if FHR.battleTime == 0 then
	-- 	for player in players.iterate do
	-- 		if not player.hr then continue end
	-- 		player.hr.qualified = false
	-- 	end
	-- 	FH:endGame()
	-- end
end

function battle:safeFinish()
	local count = 0
	local aliveCount = 0

	for player in players.iterate do
		if not player.mo then continue end
		if not player.mo.health then continue end
		if not player.hr then continue end
		if player.hasLeftServer then continue end
		if not FH:isTeamLeader(player) then continue end

		count = $ + 1

		if player.hr.spectator then
			player.hr.qualified = false -- TODO: make this make more sense and dont let spectators get into qualified within heist itself, not this gamemode
			continue
		end
		if not player.hr.qualified then continue end

		aliveCount = $ + 1
	end

	if aliveCount == 2 then
		FHR.showdown = true
		FH:changeMusic(FH:getMapVariable(nil, "fh_showdownmusic", "FH_SDN"))
	end

	if aliveCount == 1 or count == 0 then
		FH:endGame()
	end
end
