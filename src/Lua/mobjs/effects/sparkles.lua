---@diagnostic disable: undefined-global

freeslot("MT_FH_SPARKLES")
freeslot("S_FH_SPARKLE")

-- Sparkles
-- Makes sparkles fly around the target mobj.

mobjinfo[MT_FH_SPARKLES].spawnstate = S_INVISIBLE
mobjinfo[MT_FH_SPARKLES].radius = FU
mobjinfo[MT_FH_SPARKLES].height = FU
mobjinfo[MT_FH_SPARKLES].flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOGRAVITY

states[S_FH_SPARKLE].sprite = SPR_SSPK
states[S_FH_SPARKLE].frame = FF_FULLBRIGHT|FF_ADD
states[S_FH_SPARKLE].tics = -1
states[S_FH_SPARKLE].nextstate = S_FH_SPARKLE

local sparkleStart    = 4
local sparkleFinish   = 24
local sparkleDuration = 3 * TICRATE
local sparkleAlpha    = (FU / 25) * 12

--------------------------------------------------------------------------------
-- EmmyLua type definitions
--------------------------------------------------------------------------------

---@class heistSparkleController_t : mobj_t
---@field ticker tic_t                                       # Ticks elapsed, controls sparkle spawning timing.
---@field sparkleRate tic_t                                  # Number of ticks between sparkle spawns.
---@field sparkleAmount number                               # Number of sparkles to spawn per spawn event.
---@field sparkleRadius fixed_t                              # Maximum distance from origin for sparkle spawn.
---@field sparkleHeight fixed_t                              # Vertical range for sparkle spawn offset.
---@field sparkleScale fixed_t                               # Base scale of sparkles.
---@field sparkleScaleRandom fixed_t                         # Random scale variance (+/-).
---@field sparkleMom fixed_t                                 # Initial vertical momentum of sparkles.
---@field sparkleRadialMom fixed_t                           # Radial momentum applied to sparkles on spawn.
---@field sparkleOrbitSpeed angle_t                          # Orbit speed (angle per tick) of sparkles around target.
---@field sparkleLifetime tic_t                              # How long sparkles last before removal.
---@field sparkleAlphaMax fixed_t                            # Maximum alpha (opacity) value for sparkles.
---@field sparkleColor skincolornum_t|nil                    # Optional color override for sparkles.
---@field sparkleDelay tic_t                                 # Delay in ticks before sparkles start spawning.
---@field sparkleBurst boolean                               # If true, spawn once then stop.
---@field sparkleMaxCount number                             # Max number of sparkles active at once.
---@field sparkleFollowTarget boolean                        # If true, sparkles follow the target’s position.
---@field autoRemove boolean                                 # If true, controller removes itself when target invalid.
---@field stopSparkles boolean                               # When true, stops spawning new sparkles.
---@field deleteSelf boolean                                 # If true, will delete itself if stopSparkles is true and no more sparkles were made.
---@field _sparkles heistSparkle_t[]                         # Table of active sparkle mobj references.

---@class heistSparkle_t : mobj_t
---@field orbitAngle angle_t                                 # Current angle of sparkle in orbit.
---@field orbitRadius fixed_t                                # Distance from orbit center.
---@field orbitPosition {x: fixed_t, y: fixed_t, z: fixed_t} # Fixed origin point for orbit calculations.
---@field timeLeft tic_t                                     # Remaining lifespan of sparkle.


--------------------------------------------------------------------------------
-- Sparkle creation
--------------------------------------------------------------------------------

--- @param mobj heistSparkleController_t
--- @return heistSparkle_t
local function createSparkle(mobj)
	local angle  = FixedAngle(FH:fixedRandom(0, 360*FU))
	local dist   = FH:fixedRandom(0, mobj.sparkleRadius)
	local zoff   = FH:fixedRandom(-mobj.sparkleHeight, mobj.sparkleHeight)
	local target = (mobj.target and mobj.target.valid) and mobj.target or mobj

	---@type heistSparkle_t
	local sparkle = P_SpawnMobjFromMobj(
		target,
		P_ReturnThrustX(nil, angle, dist),
		P_ReturnThrustY(nil, angle, dist),
		zoff,
		MT_THOK
	) --[[@as heistSparkle_t]]

	-- Orbit data (LOCAL to sparkle, never cumulative)
	sparkle.orbitAngle  = angle
	sparkle.orbitRadius = dist
	sparkle.orbitPosition = {
		x = target.x,
		y = target.y,
		z = target.z
	}

	sparkle.fuse = -1
	sparkle.timeLeft = mobj.sparkleLifetime
	sparkle.alpha = 0
	sparkle.flags2 = $|MF2_DONTDRAW

	sparkle.scale = mobj.sparkleScale
		+ FH:fixedRandom(-mobj.sparkleScaleRandom, mobj.sparkleScaleRandom)
	sparkle.destscale = sparkle.scale

	sparkle.momz = mobj.sparkleMom
	sparkle.momx = P_ReturnThrustX(nil, angle, mobj.sparkleRadialMom)
	sparkle.momy = P_ReturnThrustY(nil, angle, mobj.sparkleRadialMom)

	if mobj.sparkleColor then
		sparkle.color = mobj.sparkleColor
	end

	sparkle.state = S_FH_SPARKLE
	table.insert(mobj._sparkles, sparkle)

	return sparkle
end

--------------------------------------------------------------------------------
-- Controller spawn
--------------------------------------------------------------------------------

--- @param mobj heistSparkleController_t
addHook("MobjSpawn", function(mobj)
	mobj.ticker = 0
	mobj.sparkleRate = 1
	mobj.sparkleAmount = 2
	mobj.sparkleRadius = 48 * FU
	mobj.sparkleHeight = 0
	mobj.sparkleScale = FU / 2
	mobj.sparkleScaleRandom = 0
	mobj.sparkleMom = FU
	mobj.sparkleRadialMom = 0
	mobj.sparkleOrbitSpeed = 0
	mobj.sparkleLifetime = sparkleDuration
	mobj.sparkleAlphaMax = sparkleAlpha
	mobj.sparkleColor = nil
	mobj.sparkleDelay = 0
	mobj.sparkleBurst = false
	mobj.sparkleMaxCount = INT32_MAX
	mobj.sparkleFollowTarget = true
	mobj.autoRemove = true
	mobj.stopSparkles = false
	mobj.deleteSelf = false

	---@protected
	---@type heistSparkle_t[]
	mobj._sparkles = {}
end, MT_FH_SPARKLES)

--------------------------------------------------------------------------------
-- Controller thinker
--------------------------------------------------------------------------------

--- @param mobj heistSparkleController_t
addHook("MobjThinker", function(mobj)
	-- Follow target
	if mobj.sparkleFollowTarget
	and mobj.target
	and mobj.target.valid then
		P_MoveOrigin(mobj, mobj.target.x, mobj.target.y, mobj.target.z)
	elseif mobj.autoRemove then
		P_RemoveMobj(mobj)
		return
	end

	-- Delay
	if mobj.sparkleDelay > 0 then
		mobj.sparkleDelay = $ - 1
		return
	end

	-- Spawning
	if not mobj.stopSparkles then
		mobj.ticker = $ + 1

		if mobj.ticker >= mobj.sparkleRate then
			mobj.ticker = 0

			for _ = 1, mobj.sparkleAmount do
				if #mobj._sparkles < mobj.sparkleMaxCount then
					createSparkle(mobj)
				end
			end

			if mobj.sparkleBurst then
				mobj.stopSparkles = true
			end
		end
	end

	if #mobj._sparkles == 0 and mobj.deleteSelf and mobj.stopSparkles then
		P_RemoveMobj(mobj)
		return
	end

	-- Sparkle logic
	for i = #mobj._sparkles, 1, -1 do
		local sparkle = mobj._sparkles[i]
		if not (sparkle and sparkle.valid) then
			table.remove(mobj._sparkles, i)
			continue
		end

		sparkle.timeLeft = $ - 1
		sparkle.flags2 = 0

		-- Orbit
		if mobj.sparkleOrbitSpeed ~= 0 then
			sparkle.orbitAngle = $ + mobj.sparkleOrbitSpeed

			P_MoveOrigin(
				sparkle,
				sparkle.orbitPosition.x + P_ReturnThrustX(nil, sparkle.orbitAngle, sparkle.orbitRadius),
				sparkle.orbitPosition.y + P_ReturnThrustY(nil, sparkle.orbitAngle, sparkle.orbitRadius),
				sparkle.z
			)

			sparkle.momx = 0
			sparkle.momy = 0
		end

		-- Lifetime end
		if sparkle.timeLeft <= 0 then
			table.remove(mobj._sparkles, i)
			P_RemoveMobj(sparkle)
			continue
		end

		-- Fade
		if sparkle.timeLeft > sparkleFinish then
			sparkle.alpha = min(
				mobj.sparkleAlphaMax,
				$ + mobj.sparkleAlphaMax / sparkleStart
			)
		else
			sparkle.alpha = max(
				0,
				$ - mobj.sparkleAlphaMax / sparkleFinish
			)
		end
	end
end, MT_FH_SPARKLES)