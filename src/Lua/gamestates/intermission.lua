local gamestate = {}

gamestate.timeLeft = 30 * TICRATE
gamestate.gameScreenBeat = 76
gamestate.gameScreenEnd = 7 * TICRATE
gamestate.intermissionBeat = gamestate.gameScreenEnd + 63
gamestate.resultsTime = gamestate.gameScreenEnd + 5 * TICRATE
gamestate.mapVoteTime = gamestate.resultsTime + 10 * TICRATE

function gamestate:init()
	-- apply MF_NOTHINK to all mobjs to ensure nothing moves. do this once as well so we dont gotta worry about lag
	for mobj in mobjs.iterate() do
		mobj.flags = $|MF_NOTHINK
	end

	FHR.intermissionStartTime = leveltime

	FHR.winningPlayers = {}

	-- get the best performing players and list them here
	for player in players.iterate do
		if not player.heistRound then continue end
		---@diagnostic disable-next-line: undefined-field
		if player.hasLeftServer then continue end

		-- TODO: gametype-based way to see if player is eligible idk
		if not player.heistRound.escaped then continue end

		local entry = {
			name = player.name,
			profit = player.heistRound.profit,
			skin = player.skin,
			color = player.skincolor
		}

		local inserted = false
		for i = 1, #FHR.winningPlayers do
			if entry.score > FHR.winningPlayers[i].score then
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
	print(self.gameScreenEnd)
end

function gamestate:load()
end

function gamestate:update()
	-- constantly set stasis to true even for new players
	-- TODO: take advantage of PlayerSpawn so this doesn't run every tic

	local tics = leveltime - FHR.intermissionStartTime

	if tics == self.gameScreenBeat then
		S_StartSound(nil, sfx_thok)
	elseif tics == self.gameScreenEnd then
		S_StartSound(nil, sfx_thok)
		print("this games winner is")
		FH:changeMusic("FH_INT")
	elseif tics == self.intermissionBeat then
		S_StartSound(nil, sfx_thok)
		print("YAAAAY")
	elseif tics ==  self.resultsTime then
		print("results")
	elseif tics == self.mapVoteTime then
		print("map vote")
	end

	for player in players.iterate do
		if not player.heistRound then return end

		player.heistRound.stasis = true

		if player.mo then
			player.mo.momx = 0
			player.mo.momy = 0
			player.mo.momz = 0
			player.mo.tics = -1
		end
	end
end

function gamestate:preUpdate() end
function gamestate:playerUpdate() end
function gamestate:playerQuit() end

FH.gamestates.intermission = gamestate