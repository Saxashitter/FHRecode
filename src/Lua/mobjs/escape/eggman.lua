local timeUntilDeath = 5 * TICRATE
local startingDistMult = 10 * FU

local chaseLerp = FU / 12
local zLerp = FU / 8

freeslot(
	"MT_FH_EGGMAN_TIMESUP",
	"S_FH_EGGMAN_TIMESUP"
)

mobjinfo[MT_FH_EGGMAN_TIMESUP].spawnstate = S_FH_EGGMAN_TIMESUP
mobjinfo[MT_FH_EGGMAN_TIMESUP].radius = 48 * FU
mobjinfo[MT_FH_EGGMAN_TIMESUP].height = 64 * FU
mobjinfo[MT_FH_EGGMAN_TIMESUP].flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOGRAVITY

states[S_FH_EGGMAN_TIMESUP].sprite = SPR_EGGM
states[S_FH_EGGMAN_TIMESUP].frame = A
states[S_FH_EGGMAN_TIMESUP].tics = -1

--- @param target mobj_t
local function canChaseTarget(target)
	if not target then return false end
	if not target.valid then return false end
	if not target.health then return false end
	if not target.player then return false end
	if not target.player.hr then return false end
	if target.player.hr.qualified then return false end

	return true
end

--- @return mobj_t|nil
local function returnTarget()
	local targets = {}
	for player in players.iterate do
		if canChaseTarget(player.mo) then
			targets[#targets + 1] = player.mo
		end
	end

	if #targets > 0 then
		return targets[P_RandomRange(1, #targets)]
	end
end

--- @param mobj mobj_t
local function chaseStart(mobj)
	local target = mobj.target

	local dist = FixedMul(mobj.radius + target.radius, startingDistMult)
	local angle = target.player.drawangle
	local x = target.x
	local y = target.y
	local z = target.z + target.height / 2 - mobj.height / 2

	x = $ + P_ReturnThrustX(nil, angle + ANGLE_180, dist)
	y = $ + P_ReturnThrustY(nil, angle + ANGLE_180, dist)

	P_SetOrigin(mobj, x, y, z)
end

--- @param mobj mobj_t
local function chaseHandler(mobj)
	local target = mobj.target
	if not canChaseTarget(target) then return end

	-- 0 → FU as time runs out
	local t = FixedDiv(timeUntilDeath - mobj.timeLeft, timeUntilDeath)
	t = FixedMul(FixedMul(t, t), t) -- cubic tighten

	-- Target center
	local tx = target.x
	local ty = target.y
	local tz = target.z + (target.height / 2) - (mobj.height / 2)

	local tAngle = R_PointToAngle2(mobj.x, mobj.y, tx, ty) + ANGLE_180
	local cosRad = FixedMul(mobj.radius + mobj.target.radius, cos(tAngle))
	local sinRad = FixedMul(mobj.radius + mobj.target.radius, sin(tAngle))

	tx = $ + cosRad
	ty = $ + sinRad

	-- Lerp from *current* position toward target
	local x = mobj.x + FixedMul(tx - mobj.x, t)
	local y = mobj.y + FixedMul(ty - mobj.y, t)
	local z = mobj.z + FixedMul(tz - mobj.z, t)
	local dist = R_PointToDist2(x, y, tx, ty)

	P_MoveOrigin(mobj, x, y, z)

	-- Face the target (optional but feels right)
	mobj.angle = R_PointToAngle2(mobj.x, mobj.y, tx, ty)

	-- Countdown
	mobj.timeLeft = $ - 1
	if mobj.timeLeft <= 0 or dist < FU * 3 / 2 then
		P_DamageMobj(target, mobj, mobj, 9999, DMG_INSTAKILL)
		return true
	end
end

--- @param mobj mobj_t
addHook("MobjSpawn", function(mobj)
	local target = returnTarget()

	mobj.timeLeft = timeUntilDeath

	if target then
		mobj.target = target
		chaseStart(mobj)
	end
end, MT_FH_EGGMAN_TIMESUP)

--- @param mobj mobj_t
addHook("MobjThinker", function(mobj)
	if not canChaseTarget(mobj.target) or chaseHandler(mobj) then
		local target = returnTarget()

		mobj.timeLeft = timeUntilDeath

		if not target then
			return
		end

		mobj.target = target
		chaseStart(mobj)
	end
end, MT_FH_EGGMAN_TIMESUP)