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
addHook("MobjSpawn", function(mobj)
	mobj.variant = 0

	states[S_FH_COLLECTIBLE].action(mobj)
end, MT_FH_COLLECTIBLE)

--- @param mobj mobj_t
addHook("MapThingSpawn", function(mobj, thing)
	mobj.variant = thing.args[0] or 0

	if mobj.variant == 1 then
		print("rare. spawn sparkles and overlay slightly blue")

		local overlay = P_SpawnMobjFromMobj(mobj, 0,0,0, MT_FH_OVERLAY)
		overlay.alpha = FU / 3
		overlay.translation = "FH_AllBlue"
		overlay.target = mobj
	elseif mobj.variant == 2 then
		print("exclusive. overlay yellow over it")

		local overlay = P_SpawnMobjFromMobj(mobj, 0,0,0, MT_FH_OVERLAY)
		overlay.alpha = FU / 3
		overlay.translation = "FH_AllYellow"
		overlay.target = mobj
	end
end, MT_FH_COLLECTIBLE)

--- @param mobj mobj_t
--- @param collided mobj_t
addHook("MobjCollide", function(mobj, collided)
	print("huh")
end, MT_FH_COLLECTIBLE)