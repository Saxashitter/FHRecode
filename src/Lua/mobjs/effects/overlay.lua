freeslot("MT_FH_OVERLAY")

--- Overlay
--- Copies the exact appear of the target mobj, minus effects.
--- Useful for your own effects, like character flashes and what not.

mobjinfo[MT_FH_OVERLAY].radius = FU
mobjinfo[MT_FH_OVERLAY].height = FU
mobjinfo[MT_FH_OVERLAY].spawnstate = S_INVISIBLE
mobjinfo[MT_FH_OVERLAY].flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOBLOCKMAP
mobjinfo[MT_FH_OVERLAY].dispoffset = 1

--- @param mobj mobj_t
addHook("MobjSpawn", function(mobj)
	--- The ticker for the mobj, used for effects like mobj.alphaFuse.
	--- @type tic_t
	mobj.ticker = 0

	--- If it's not -1, then the mobj will fade out before eventually deleting itself.
	--- This should be set on spawn. If not, then at the very least reset mobj.ticker.
	--- @type tic_t
	mobj.alphaFuse = -1

	--- What flags should be applied to the frame of this object?
	--- @type UINT16
	mobj.frameFlags = 0
end, MT_FH_OVERLAY)

--- @param mobj_t
addHook("MobjThinker", function(mobj)
	if not mobj.target then P_RemoveMobj(mobj) return end
	if not mobj.target.valid then P_RemoveMobj(mobj) return end

	--- @type mobj_t
	local target = mobj.target

	mobj.state = target.state
	mobj.sprite = target.sprite
	if target.type == MT_PLAYER then
		mobj.skin = target.skin
		mobj.sprite2 = target.sprite2
	end
	mobj.frame = (target.frame & FF_FRAMEMASK)|mobj.frameFlags
	mobj.tics = target.tics

	P_MoveOrigin(mobj, target.x, target.y, target.z)
	mobj.radius = target.radius
	mobj.height = target.height
	mobj.angle = target.angle

	if mobj.alphaFuse > 0 then
		local div = FixedDiv(mobj.ticker, mobj.alphaFuse)

		mobj.alpha = FU - div

		if mobj.ticker >= mobj.alphaFuse then
			P_RemoveMobj(mobj)
			return
		end
	end

	mobj.ticker = $ + 1
end, MT_FH_OVERLAY)