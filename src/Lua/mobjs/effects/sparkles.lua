freeslot("MT_FH_SPARKLES")

-- Sparkles
-- Makes sparkles fly around the target mobj.

mobjinfo[MT_FH_SPARKLES].spawnstate = S_INVISIBLE
mobjinfo[MT_FH_SPARKLES].radius = FU
mobjinfo[MT_FH_SPARKLES].height = FU
mobjinfo[MT_FH_SPARKLES].flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOGRAVITY

local sparkleStart = 16
local sparkleFinish = 5

--- @param mobj mobj_t
--- @return mobj_t
local function createSparkle(mobj)
	--- @type mobj_t
	local sparkle = P_SpawnMobjFromMobj(mobj,
		FH:randomFixed(-mobj.sparkleRadius, mobj.sparkleRadius),
		FH:randomFixed(-mobj.sparkleRadius, mobj.sparkleRadius),
		0,
		MT_THOK
	)

	sparkle.fuse = -1
	sparkle.timeLeft = 5 * TICRATE
	sparkle.alpha = 0

	return sparkle
end

--- @param mobj mobj_t
addHook("MobjSpawn", function(mobj)
	--- The amount of times this ticked.
	--- @type tic_t
	mobj.ticker = 0

	--- Everytime the ticker reaches over this number, it spawns a sparkle.
	--- @type tic_t
	mobj.sparkleRate = 15

	--- How far apart should the sparkles be?
	--- @type fixed_t
	mobj.sparkleRadius = 48 * FU

	--- The scale of every sparkle.
	--- @type fixed_t
	mobj.sparkleScale = FU

	--- How fast should the sparkles
end, MT_FH_SPARKLES)