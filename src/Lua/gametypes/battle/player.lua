local battle = _FH_BATTLE

--- @class heistPlayerRound_t
--- The player's current stock counter. Used in Battle.
--- @field stocks boolean

function battle:playerInit(player, currentState)
	player.hr.stocks = self.stocks
	player.hr.qualified = true

	if currentState == "game" then
		player.hr.stocks = 0
		player.hr.spectator = true
		player.hr.qualified = false

		player.spectator = true
	end
end

function battle:playerDeath(player, currentState)
	if currentState ~= "game" then return end

	if player.hr.qualified then
		player.hr.qualified = false
		player.hr.spectator = true

		self:safeFinish()
	end
end
battle.playerQuit = battle.playerDeath