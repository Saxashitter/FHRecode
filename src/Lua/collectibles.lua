freeslot("MT_FH_COLLECTIBLE", "S_FH_COLLECTIBLE")

local uncaughtFlags = 0
local caughtFlags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOBLOCKMAP

FH.collectibleCommon = 0
FH.collectibleRare = 1
FH.collectibleExclusive = 2

---@diagnostic disable-next-line: missing-fields
mobjinfo[MT_FH_COLLECTIBLE] = {
	--$Title Collectible
	--$Category Fang's Heist - Items
	--$Sprite TRESI0
	--$Arg0 Variant (0-2)
	--$Arg1 Forced Frame (A-I)
	doomednum = 4097,
	spawnstate = S_FH_COLLECTIBLE,
	radius = 24 * FU / 2,
	height = 24 * FU,
	flags = uncaughtFlags
}

states[S_FH_COLLECTIBLE].sprite = freeslot("SPR_TRES")
states[S_FH_COLLECTIBLE].frame = 0
states[S_FH_COLLECTIBLE].tics = -1
states[S_FH_COLLECTIBLE].action = function(mobj) mobj.frame = ($ & ~FF_FRAMEMASK)|P_RandomRange(A, J) end

--- @param mobj mobj_t
addHook("MobjThinker", function(mobj)
	local variant = mobj.spawnpoint.args[0]

	print(variant)
end, MT_FH_COLLECTIBLE)

--- @param mobj mobj_t
--- @param collided mobj_t
addHook("MobjCollide", function(mobj, collided)
	print("huh")
end, MT_FH_COLLECTIBLE)