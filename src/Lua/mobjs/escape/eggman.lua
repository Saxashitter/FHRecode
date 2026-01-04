-- TODO: refactor maybe to be more clean

local APPROACH_ACCEL   = FU / 2
local SECONDS_TILL_DEATH = 5 * TICRATE

local EGG_APPROACH = 1
local EGG_KILL     = 2
local EGG_LAUGH    = 3

freeslot(
	"MT_FH_EGGMAN_TIMESUP",
	"S_FH_EGGMAN_TIMESUP_CHASE",
	"S_FH_EGGMAN_TIMESUP_LAUGH",
	"S_FH_EGGMAN_TIMESUP_ATTACK0",
	"S_FH_EGGMAN_TIMESUP_ATTACK1",
	"S_FH_EGGMAN_TIMESUP_ATTACK2",
	"S_FH_EGGMAN_TIMESUP_ATTACK3",
	"S_FH_EGGMAN_TIMESUP_ATTACK4",
	"S_FH_EGGMAN_TIMESUP_ATTACK5",
	"S_FH_EGGMAN_TIMESUP_ATTACK6",
	"S_FH_EGGMAN_TIMESUP_ATTACK7",
	"S_FH_EGGMAN_TIMESUP_LAUGH1",
	"S_FH_EGGMAN_TIMESUP_LAUGH2"
)

mobjinfo[MT_FH_EGGMAN_TIMESUP] = {
	radius = 48 * FU,
	height = 64 * FU,
	flags  = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY,
	spawnstate = S_FH_EGGMAN_TIMESUP_CHASE
}

states[S_FH_EGGMAN_TIMESUP_CHASE]   = {SPR_EGGM, A, -1,nil, 0, 5, S_FH_EGGMAN_TIMESUP_CHASE  }

states[S_FH_EGGMAN_TIMESUP_ATTACK0] = {SPR_EGGM, A, 2, nil, 0, 5, S_FH_EGGMAN_TIMESUP_ATTACK1}
states[S_FH_EGGMAN_TIMESUP_ATTACK1] = {SPR_EGGM, B, 2, nil, 0, 5, S_FH_EGGMAN_TIMESUP_ATTACK2}
states[S_FH_EGGMAN_TIMESUP_ATTACK2] = {SPR_EGGM, C, -1,nil, 0, 5, S_FH_EGGMAN_TIMESUP_ATTACK3}
states[S_FH_EGGMAN_TIMESUP_ATTACK3] = {SPR_EGGM, D, 1, nil, 0, 5, S_FH_EGGMAN_TIMESUP_ATTACK4}
states[S_FH_EGGMAN_TIMESUP_ATTACK4] = {SPR_EGGM, E, 1, nil, 0, 5, S_FH_EGGMAN_TIMESUP_ATTACK5}
states[S_FH_EGGMAN_TIMESUP_ATTACK5] = {SPR_EGGM, F, 1, nil, 0, 5, S_FH_EGGMAN_TIMESUP_ATTACK6}
states[S_FH_EGGMAN_TIMESUP_ATTACK6] = {SPR_EGGM, G, 1, nil, 0, 5, S_FH_EGGMAN_TIMESUP_ATTACK7}
states[S_FH_EGGMAN_TIMESUP_ATTACK7] = {SPR_EGGM, H, 1, nil, 0, 5, S_FH_EGGMAN_TIMESUP_ATTACK6}

states[S_FH_EGGMAN_TIMESUP_LAUGH1]  = {SPR_EGGM, R, 2, nil, 0, 5, S_FH_EGGMAN_TIMESUP_LAUGH2 }
states[S_FH_EGGMAN_TIMESUP_LAUGH2]  = {SPR_EGGM, S, 2, nil, 0, 5, S_FH_EGGMAN_TIMESUP_LAUGH1 }

local function validPlayer(player)
	if not player or not player.valid or not player.heistRound or player.heistRound.escaped or player.heistRound.downed or player.heistRound.spectator then
		return false
	end

	return true
end

local function getClosestPlayer(eggman)
	local best, bestdist

	for p in players.iterate do
		local mo = p.mo
		if not (mo and mo.valid and mo.health) then continue end
		if not validPlayer(p) then continue end

		local dist = R_PointToDist2(
			0, eggman.z,
			R_PointToDist2(eggman.x, eggman.y, mo.x, mo.y),
			mo.z
		)

		if not best or dist < bestdist then
			best = mo
			bestdist = dist
		end
	end

	return best, bestdist
end

local function ensureTarget(eggman)
	if eggman.target and eggman.target.valid and eggman.target.player and validPlayer(eggman.target.player) then
		return true
	end

	local target = getClosestPlayer(eggman)
	if not target then return false end

	eggman.target = target
	eggman.approachSpeed = 0
	eggman.secondsLeft = SECONDS_TILL_DEATH
	eggman.eggState = EGG_APPROACH

	return true
end

local function approachPlayer(eggman)
	if not ensureTarget(eggman) then return end

	eggman.approachSpeed = $ + APPROACH_ACCEL

	local t = eggman.target

	local ex = eggman.x
	local ey = eggman.y
	local ez = eggman.z + eggman.height/2

	local tx = t.x
	local ty = t.y
	local tz = t.z + t.height/2

	local dist = R_PointToDist2(0, ez, R_PointToDist2(ex, ey, tx, ty), tz)

	if dist <= eggman.radius + t.radius then
		eggman.momx, eggman.momy, eggman.momz = 0, 0, 0
		eggman.approachSpeed = 0
		eggman.state = S_FH_EGGMAN_TIMESUP_ATTACK1
		eggman.eggState = EGG_KILL
		return
	end

	local angle  = R_PointToAngle2(ex, ey, tx, ty)
	local aiming = R_PointToAngle2(0, 0, dist, tz - ez)
	local speed  = min(eggman.approachSpeed, dist)

	P_InstaThrust(eggman, angle, FixedMul(speed, cos(aiming)))
	P_SetObjectMomZ(eggman, FixedMul(speed, sin(aiming)))
	eggman.angle = angle
end

local function prepareToDie(eggman)
	if not ensureTarget(eggman) then
		eggman.eggState = EGG_APPROACH
		eggman.state = S_FH_EGGMAN_TIMESUP_CHASE
		return
	end

	local t = eggman.target
	local angle = FixedAngle(leveltime * (360 * FU / 50))
	local dist  = 128 * FU

	local x = t.x + P_ReturnThrustX(nil, angle, dist)
	local y = t.y + P_ReturnThrustY(nil, angle, dist)
	local z = t.z + t.height

	P_MoveOrigin(eggman, x, y, z)
	eggman.angle = R_PointToAngle2(x, y, t.x, t.y)
	eggman.secondsLeft = $ - 1

	if eggman.secondsLeft == F then
		eggman.state = S_FH_EGGMAN_TIMESUP_ATTACK4
	end

	if eggman.secondsLeft <= 0 then
		if P_DamageMobj(t, eggman, eggman, 100, DMG_INSTAKILL) then
			eggman.state = S_FH_EGGMAN_TIMESUP_LAUGH1
			eggman.laughTime = 2 * TICRATE
			eggman.eggState = EGG_LAUGH
		else
			eggman.state = S_FH_EGGMAN_TIMESUP_ATTACK0
		end

		eggman.secondsLeft = SECONDS_TILL_DEATH
	end
end

local function laughAndStuff(eggman)
	eggman.laughTime = $ - 1

	if not eggman.laughTime then
		eggman.state = S_FH_EGGMAN_TIMESUP_CHASE
		eggman.eggState = EGG_APPROACH
	end
end

addHook("MobjSpawn", function(mo)
	mo.approachSpeed = 0
	mo.secondsLeft   = SECONDS_TILL_DEATH
	mo.eggState      = EGG_APPROACH
	ensureTarget(mo)
end, MT_FH_EGGMAN_TIMESUP)

addHook("MobjThinker", function(mo)
	if mo.eggState == EGG_APPROACH then
		approachPlayer(mo)
	elseif mo.eggState == EGG_KILL then
		prepareToDie(mo)
	elseif mo.eggState == EGG_LAUGH then
		laughAndStuff(mo)
	end
end, MT_FH_EGGMAN_TIMESUP)

COM_AddCommand("fh_spawneggman", function()
	P_SpawnMobj(0, 0, 0, MT_FH_EGGMAN_TIMESUP)
end)
