local gamestate = {}

gamestate.timeLeft = 30 * TICRATE
gamestate.gameScreenBeat = 2160 * TICRATE / MUSICRATE
gamestate.gameScreenEnd = 7 * TICRATE
gamestate.intermissionBeat = 63
gamestate.resultsTime = 5 * TICRATE
gamestate.mapVoteTime = 10 * TICRATE

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

	-- get the best performing players and list them here
	for player in players.iterate do
		if not player.heistRound then continue end
		---@diagnostic disable-next-line: undefined-field
		if player.hasLeftServer then continue end

		-- TODO: gametype-based way to see if player is eligible idk
		if not player.heistRound.escaped then continue end

		-- sort table
		table.sort(player.heistRound.profitLog, function(a, b) return a.profit > b.profit end)

		local entry = {
			name = player.name,
			profit = player.heistRound.profit,
			skin = player.skin,
			color = player.skincolor,
			log = player.heistRound.profitLog
		}

		local inserted = false
		for i = 1, #FHR.winningPlayers do
			if entry.profit > FHR.winningPlayers[i].profit then
				inserted = true
				table.insert(FHR.winningPlayers, i, entry)

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
		-- TODO: make results
	end

	if tics == self.mapVoteTime then
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