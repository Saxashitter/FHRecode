local gamestate = {}

gamestate.timeLeft = 30 * TICRATE
gamestate.gameScreenBeat = 3125 * TICRATE / MUSICRATE
gamestate.gameScreenEnd = 7 * TICRATE
gamestate.intermissionBeat = 63
gamestate.resultsTime = 10 * TICRATE

sfxinfo[freeslot("sfx_fh_gme")].caption = "GAME!!"
sfxinfo[freeslot("sfx_fh_tgw")].caption = "This game's winner is..."
sfxinfo[freeslot("sfx_fh_ch1")].caption = "WOOOO!!!"
sfxinfo[freeslot("sfx_fh_ch2")].caption = "YAY!!!"

function gamestate:init()
	-- apply MF_NOTHINK to all mobjs to ensure nothing moves. do this once as well so we dont gotta worry about lag
	for mobj in mobjs.iterate() do
		mobj.flags = $|MF_NOTHINK
	end

	S_StartSound(nil, sfx_s24f)
	FHR.intermissionStartTime = leveltime

	FHR.winningPlayers = {}

	local queuedTeams = {}
	for player in players.iterate do
		if not player.heistRound then continue end
		local team = player.heistGlobal.team
		if queuedTeams[team] then continue end  -- already processed this team

		-- check if any player in this team has escaped
		local teamHasEscaped = false
		for _, member in ipairs(team.players) do
			if member.heistRound.escaped then
				teamHasEscaped = true
				break
			end
		end

		if not teamHasEscaped then continue end  -- skip team if no one escaped

		-- get the leader of the team
		local leader = team.players[1]
		if not leader then continue end

		-- mark the team as processed
		queuedTeams[team] = true

		-- sort leader's profit log
		table.sort(leader.heistRound.profitLog, function(a, b) return a.profit > b.profit end)

		-- create leaderboard entry
		local entry = {
			name = leader.name,
			profit = leader.heistRound.profit,
			skin = leader.skin,
			color = leader.skincolor,
			log = leader.heistRound.profitLog,
			player = leader,
			team = team
		}

		-- insert into winningPlayers in order of profit
		local inserted = false
		for i = 1, #FHR.winningPlayers do
			if entry.profit > FHR.winningPlayers[i].profit then
				table.insert(FHR.winningPlayers, i, entry)
				inserted = true
				break
			end
		end
		if not inserted then
			FHR.winningPlayers[#FHR.winningPlayers + 1] = entry
		end
	end


	FH:changeMusic("FH_END", false)
end

function gamestate:load()
end

function gamestate:update()
	-- constantly set stasis to true even for new players
	-- TODO: take advantage of PlayerSpawn so this doesn't run every tic

	local tics = leveltime - FHR.intermissionStartTime

	if tics == self.gameScreenBeat then
		S_StartSoundAtVolume(nil, sfx_fh_gme, 75)
		S_StartSoundAtVolume(nil, sfx_s3k9c, 75)
		S_StartSoundAtVolume(nil, sfx_s3kb3, 100)
	end
	
	if tics == self.gameScreenEnd then
		S_StartSoundAtVolume(nil, sfx_fh_tgw, 70)
		FH:changeMusic("FH_INT")
	end

	tics = $ - self.gameScreenEnd

	if tics == self.intermissionBeat then
		S_StartSoundAtVolume(nil, sfx_fh_ch1, 50)
		S_StartSoundAtVolume(nil, sfx_fh_ch1, 75)
	end

	if tics == self.resultsTime then
		FH:setGamestate("mapvote")
	end
end

function gamestate:preUpdate() end
function gamestate:playerUpdate(player)
	player.heistRound.stasis = true

	if player.mo then
		player.mo.momx = 0
		player.mo.momy = 0
		player.mo.momz = 0
		player.mo.tics = -1
	end
end
function gamestate:playerQuit() end

addHook("ShouldDamage", function(target)
	local gametype = FH:isMode()

	if not gametype then return end

	if FHR.currentState == "intermission" then return false end
end)

FH.gamestates.intermission = gamestate