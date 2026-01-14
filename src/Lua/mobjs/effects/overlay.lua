freeslot("MT_FH_OVERLAY")

-- Overlay
-- Draws a sprite over the player.

mobjinfo[MT_FH_OVERLAY].radius = FU
mobjinfo[MT_FH_OVERLAY].height = FU
mobjinfo[MT_FH_OVERLAY].spawnstate = S_INVISIBLE
mobjinfo[MT_FH_OVERLAY].flags = MF_NOCLIP | MF_NOCLIPHEIGHT | MF_NOGRAVITY | MF_NOBLOCKMAP
mobjinfo[MT_FH_OVERLAY].dispoffset = 1

---@class heistOverlay_t : mobj_t
---@field ticker tic_t               # Ticks elapsed since spawn, used for timing effects.
---@field alphaFuse tic_t            # Duration of alpha fade; -1 means no fade.
---@field frameFlags UINT16          # Extra frame flags to apply to overlay frames.
---@field target mobj_t|nil          # The mobj this overlay copies the appearance of.
---@field autoRemove boolean         # If true, overlay deletes itself when target invalid.
---@field alphaStart fixed_t         # Starting alpha value for fade (fixed-point).
---@field alphaEnd fixed_t           # Ending alpha value for fade (fixed-point).
---@field translation string|nil     # Optional palette translation string.

---@param mobj heistOverlay_t
addHook("MobjSpawn", function(mobj)
	mobj.ticker = 0
	mobj.alphaFuse = -1
	mobj.frameFlags = 0
	mobj.autoRemove = true
	mobj.alphaStart = FU
	mobj.alphaEnd = 0
	mobj.translation = nil
end, MT_FH_OVERLAY)

---@param mobj heistOverlay_t
addHook("MobjThinker", function(mobj)
	if not mobj.target or not mobj.target.valid then
		if mobj.autoRemove then
			P_RemoveMobj(mobj)
			return
		end
	end

	---@type mobj_t
	local target = mobj.target

	if target then
		mobj.state = target.state
		mobj.sprite = target.sprite
		if target.type == MT_PLAYER then
			mobj.skin = target.skin
			mobj.sprite2 = target.sprite2
		end
		mobj.frame = (target.frame & FF_FRAMEMASK) | mobj.frameFlags
		mobj.tics = target.tics
		mobj.radius = target.radius
		mobj.height = target.height
		mobj.angle = target.angle
		if target.type == MT_PLAYER and target.player then
			mobj.angle = target.player.drawangle
		end
		mobj.eflags = $|(target.eflags & MFE_VERTICALFLIP)

		P_MoveOrigin(mobj, target.x, target.y, target.z)
	end

	if mobj.alphaFuse > 0 then
		local fadeProgress = FixedDiv(mobj.ticker, mobj.alphaFuse)
		local alphaDiff = mobj.alphaStart - mobj.alphaEnd
		mobj.alpha = mobj.alphaStart - FixedMul(alphaDiff, fadeProgress)

		if mobj.ticker >= mobj.alphaFuse then
			P_RemoveMobj(mobj)
			return
		end
	end

	mobj.ticker = $ + 1
end, MT_FH_OVERLAY)
