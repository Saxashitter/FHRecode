local gamestate = {}

gamestate.timeLeft = 10 * TICRATE

function gamestate:init()
	-- apply MF_NOTHINK to all mobjs to ensure nothing moves. do this once as well so we dont gotta worry about lag
	for mobj in mobjs.iterate() do
		mobj.flags = $|MF_NOTHINK
	end

	FHR.intermissionTime = self.timeLeft

	-- get the best performing player and list them here
	local winner

	for player in players.iterate do
		if not player.heistRound then continue end
		---@diagnostic disable-next-line: undefined-field
		if player.hasLeftServer then continue end

		-- TODO: gametype-based way to see if player is eligible idk
		if not player.heistRound.escaped then continue end

		if not winner then
			winner = player
			continue
		end

		if player.score > winner.score then
			winner = player
			continue
		end
	end

	if winner then
		FHR.winningPlayer = {
			name = winner.name,
			profit = winner.heistRound.profit,
			skin = winner.skin,
			color = winner.skincolor
		}
	end

	S_FadeMusic(0, MUSICRATE)
end

function gamestate:load()
end

function gamestate:update()
	-- constantly set stasis to true even for new players
	-- TODO: take advantage of PlayerSpawn so this doesn't run every tic

	FHR.intermissionTime = $ - 1

	if FHR.intermissionTime == 0 then
		G_ExitLevel()
		return
	end

	for player in players.iterate do
		if not player.heistRound then return end

		player.heistRound.stasis = true
		player.mo.momx = 0
		player.mo.momy = 0
		player.mo.momz = 0
		player.mo.tics = -1
	end
end

function gamestate:preUpdate() end
function gamestate:playerUpdate() end
function gamestate:playerQuit() end

FH.gamestates.intermission = gamestate