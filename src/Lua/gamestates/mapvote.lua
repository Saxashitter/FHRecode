local gamestate = {}

gamestate.timeLeft = 10 * TICRATE

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
	FHR.mapVoteTime = leveltime

	-- TODO: random maps based on gametype typeoflevel (and random modes once we get to that)
	FHR.mapVoteMaps = {
		1,
		2,
		30
	}

	FH:changeMusic("FH_MPV", false)
end

function gamestate:load()
end

function gamestate:update()
	local tics = leveltime - FHR.mapVoteTime

	if tics == self.timeLeft then
		self:switch()
		return
	end
end

function gamestate:switch()
	local map = FHR.mapVoteMaps[P_RandomRange(1, #FHR.mapVoteMaps)]
	local voteNum = -1

	local votes = {}
	for i = 1, #FHR.mapVoteMaps do
		votes[i] = 0
	end

	for player in players.iterate do
		if not player.heistRound then continue end
		---@diagnostic disable-next-line: undefined-field
		if player.hasLeftServer then continue end
		if not player.heistRound.mapVote then continue end

		votes[player.heistRound.mapSelection] = $ + 1
	end

	-- now decide the map
	for i, vote in ipairs(votes) do
		if vote > voteNum then
			map = FHR.mapVoteMaps[i]
			voteNum = vote
		end
	end

	G_SetCustomExitVars(map, voteNum)
	G_ExitLevel()

	if map == gamemap then
		FHN.retakes = $ + 1
		print("Retake number #"..FHN.retakes)
	else
		FHN.retakes = 0
	end
end

function gamestate:canSwitch()
	local count = 0
	local votedCount = 0

	for player in players.iterate do
		if not player.heistRound then continue end
		---@diagnostic disable-next-line: undefined-field
		if player.hasLeftServer then continue end

		count = $ + 1
		if player.heistRound.mapVote then
			votedCount = $ + 1
		end
	end

	return votedCount >= count
end


function gamestate:preUpdate() end

-- TODO: take advantage of PlayerSpawn to stop whatever tf this is for new players
function gamestate:playerUpdate(player)
	player.heistRound.stasis = true

	if player.mo then
		player.mo.momx = 0
		player.mo.momy = 0
		player.mo.momz = 0
		player.mo.tics = -1
	end

	local x, _ = FH:isMovePressed(player, 25)
	local confirmed = FH:isButtonPressed(player, BT_JUMP)
	local revert = FH:isButtonPressed(player, BT_SPIN)

	if x ~= 0 and not player.heistRound.mapVote then
		player.heistRound.mapSelection = $ + x

		if player.heistRound.mapSelection > #FHR.mapVoteMaps then
			player.heistRound.mapSelection = 1
		elseif player.heistRound.mapSelection < 1 then
			player.heistRound.mapSelection = #FHR.mapVoteMaps
		end

		S_StartSound(nil, sfx_kc39, player)
	end

	if confirmed and not player.heistRound.mapVote then
		S_StartSound(nil, sfx_kc5e, player)
		player.heistRound.mapVote = true

		if self:canSwitch() then
			self:switch()
		end
	end
	
	if revert and player.heistRound.mapVote then
		S_StartSound(nil, sfx_kc5d, player)
		player.heistRound.mapVote = false
	end
end
--- @param player player_t
function gamestate:playerQuit(player)
	if self:canSwitch() then
		self:switch()
	end
end

addHook("ShouldDamage", function(target)
	local gametype = FH:isMode()

	if not gametype then return end

	if FHR.currentState == "mapvote" then return false end
end)

FH.gamestates.mapvote = gamestate