local gamestate = {}

function gamestate:init()
	-- apply MF_NOTHINk to all mobjs to ensure nothing moves. do this once as well so we dont gotta worry about lag

	for mobj in mobjs.iterate() do
		mobj.flags = $|MF_NOTHINK
	end
end

function gamestate:update()
	-- constantly set stasis to true even for new players
	-- TODO: take advantage of PlayerSpawn so this doesn't run every tic

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
function gamestate:playerUpdate()
end

FH.gamestates.intermission = gamestate