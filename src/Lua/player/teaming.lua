freeslot("MT_FH_TEAM", "S_FH_TEAM", "SPR_FHTM")

-- =====================
-- STATE / MOBJ SETUP
-- =====================

states[S_FH_TEAM].sprite = SPR_FHTM
states[S_FH_TEAM].frame = A
states[S_FH_TEAM].tics = 10 * TICRATE

mobjinfo[MT_FH_TEAM].spawnstate = S_FH_TEAM
mobjinfo[MT_FH_TEAM].radius = FU
mobjinfo[MT_FH_TEAM].height = FU
mobjinfo[MT_FH_TEAM].dispoffset = 1
mobjinfo[MT_FH_TEAM].flags =
	MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOBLOCKMAP

FH.teamRange = 128 * FU
FH.teamLimit = 3

-- =====================
-- TEAM REQUEST MOBJ
-- =====================

--- @param mobj mobj_t
addHook("MobjSpawn", function(mobj)
	mobj.spriteyscale = 0
end, MT_FH_TEAM)

--- @param mobj mobj_t
addHook("MobjThinker", function(mobj)
	if not (mobj.target and mobj.target.valid and mobj.target.health) then
		P_RemoveMobj(mobj)
		return
	end

	local target = mobj.target

	P_MoveOrigin(
		mobj,
		target.x,
		target.y,
		target.z + target.height + target.scale * 12
	)

	mobj.spriteyscale = ease.linear(FU / 3, $, FU)
end, MT_FH_TEAM)

--- @param mobj mobj_t
addHook("MobjRemoved", function(mobj)
	if mobj.target
	and mobj.target.valid
	and mobj.target.player
	and mobj.target.player.heistRound
	and mobj.target.player.heistRound.teamMobj == mobj then
		mobj.target.player.heistRound.teamMobj = nil
	end
end, MT_FH_TEAM)

-- =====================
-- CORE TEAM QUERIES
-- =====================

--- @param player player_t
--- @return boolean
function FH:canUseTeamInput(player)
	if not FH:isMode() then return false end
	if FHR.currentState ~= "game" then return false end
	if not player.heistRound then return false end
	if not (player.mo and player.mo.health) then return false end
	if P_PlayerInPain(player) then return false end
	return true
end

--- Finds a leader this player can join
--- @param player player_t
--- @return player_t|nil
function FH:getJoinableLeader(player)
	for leader in players.iterate do
		if not leader.heistGlobal then continue end
		if not FH:isTeamLeader(leader) then continue end
		if not leader.heistRound.teamMobj then continue end
		if #leader.heistGlobal.team.players >= FH.teamLimit then continue end
		if FH:isInTeam(leader, player) then continue end

		if FH:isPlayerInTeamingRange(leader, player) then
			return leader
		end
	end

	return nil
end

--- @param player player_t
--- @return boolean
function FH:canCreateTeamRequest(player)
	if not FH:isTeamLeader(player) then return false end
	if player.heistRound.teamMobj then return false end
	if #player.heistGlobal.team.players >= FH.teamLimit then return false end
	return true
end

-- =====================
-- PLAYER INPUT
-- =====================

--- @param player player_t
addHook("PlayerThink", function(player)
	if not FH:canUseTeamInput(player) then return end

	-- fresh Toss Flag press only
	if player.cmd.buttons & BT_TOSSFLAG == 0
	or player.lastbuttons & BT_TOSSFLAG > 0 then
		return
	end

	-- =====================
	-- TRY JOIN FIRST
	-- =====================

	local leader = FH:getJoinableLeader(player)

	if leader then
		FH:startTeam(leader, player)
		P_RemoveMobj(leader.heistRound.teamMobj)
		S_StartSound(player.mo, sfx_itemup)
		return
	end

	-- =====================
	-- TRY CREATE
	-- =====================

	if FH:canCreateTeamRequest(player) then
		FH:teamRequest(player)
	end
end)

-- =====================
-- TEAM LOGIC
-- =====================

--- Spawns a team request mobj above the leader
--- @param player player_t
function FH:teamRequest(player)
	local team = P_SpawnMobjFromMobj(
		player.mo,
		0, 0,
		player.mo.z + player.mo.height + player.mo.scale * 12,
		MT_FH_TEAM
	)

	if not (team and team.valid) then return end

	team.target = player.mo
	team.scale = $ * 2
	team.destscale = team.scale

	player.heistRound.teamMobj = team

	S_StartSound(player.mo, sfx_hidden)
end

--- Checks 3D distance between two players
--- @param player player_t
--- @param target player_t
--- @return boolean
function FH:isPlayerInTeamingRange(player, target)
	local dx = target.mo.x - player.mo.x
	local dy = target.mo.y - player.mo.y
	local dz =
		(target.mo.z + target.mo.height / 2)
		- (player.mo.z + player.mo.height / 2)

	return FixedHypot(FixedHypot(dx, dy), dz) < FH.teamRange
end

--- Removes player from their current team and reinitializes solo
--- @param player player_t
function FH:finishTeam(player)
	local curTeam = player.heistGlobal.team.players

	for k, v in ipairs(curTeam) do
		if v == player then
			if k == 1 and curTeam[2] then
				curTeam[2].heistRound.profit = player.heistRound.profit
				curTeam[2].heistRound.profitLog = player.heistRound.profitLog
			end

			table.remove(curTeam, k)
			break
		end
	end

	player.heistRound.profit = 0
	player.heistRound.profitLog = {}

	player.heistGlobal.team = FH:initTeam(player)
end

--- Adds target to leader's team
--- @param player player_t
--- @param target player_t
function FH:startTeam(player, target)
	FH:finishTeam(target)

	table.insert(player.heistGlobal.team.players, target)
	target.heistGlobal.team = player.heistGlobal.team

	-- iterate thru collectibles
	for _, collectible in ipairs(target.heistRound.collectibles) do
		FH:addProfit(player, FH.profitCVars.collectible.value + FH.profitCVars.collectibleExt.value * collectible.variant, "Collected "..self.collectibleNames[collectible.variant].." Collectible", 0)
	end

	print("Team initialized between "..player.name.." and "..target.name)
end

--- @param player player_t
--- @param target player_t
--- @return boolean
--- @return integer
function FH:isInTeam(player, target)
	for k, v in ipairs(player.heistGlobal.team.players) do
		if v == target then
			return true, k
		end
	end

	return false, 0
end

--- @param player player_t
--- @return boolean
function FH:isTeamLeader(player)
	return player.heistGlobal.team.players[1] == player
end

-- =====================
-- UI HELPERS
-- =====================

--- @param player player_t
--- @return boolean
function FH:shouldShowJoinTeamUI(player)
	if not FH:canUseTeamInput(player) then return false end
	return FH:getJoinableLeader(player) ~= nil
end

--- @param player player_t
--- @return boolean
function FH:shouldShowCreateTeamUI(player)
	if not FH:canUseTeamInput(player) then return false end
	return FH:canCreateTeamRequest(player)
end

--- @param player player_t
--- @return player_t|nil
function FH:getTeamUILeader(player)
	return FH:getJoinableLeader(player)
end
