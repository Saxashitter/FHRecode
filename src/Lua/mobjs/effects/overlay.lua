freeslot("MT_FH_OVERLAY")

-- Base mobjinfo setup for overlay mobj.
mobjinfo[MT_FH_OVERLAY].radius = FU
mobjinfo[MT_FH_OVERLAY].height = FU
mobjinfo[MT_FH_OVERLAY].spawnstate = S_INVISIBLE
mobjinfo[MT_FH_OVERLAY].flags = MF_NOCLIP | MF_NOCLIPHEIGHT | MF_NOGRAVITY | MF_NOBLOCKMAP
mobjinfo[MT_FH_OVERLAY].dispoffset = 1

-------------------------------------------------------------------------------------------
-- EmmyLua type definitions
-------------------------------------------------------------------------------------------

--- FH_Overlay mobj type with extra properties for overlay effects.
---@class heistOverlay_t : mobj_t
---@field ticker tic_t               # Ticks elapsed since spawn, used for timing effects.
---@field alphaFuse tic_t            # Duration of alpha fade; -1 means no fade.
---@field frameFlags UINT16          # Extra frame flags to apply to overlay frames.
---@field target mobj_t|nil          # The mobj this overlay copies the appearance of.
---@field autoRemove boolean         # If true, overlay deletes itself when target invalid.
---@field alphaStart fixed_t         # Starting alpha value for fade (fixed-point).
---@field alphaEnd fixed_t           # Ending alpha value for fade (fixed-point).
---@field translation string|nil     # Optional palette translation string.

-------------------------------------------------------------------------------------------
-- Overlay creation
-------------------------------------------------------------------------------------------

--- Initializes default properties for FH_Overlay on spawn.
---@param mobj heistOverlay_t
addHook("MobjSpawn", function(mobj)
	--- Ticks elapsed for timing effects.
	mobj.ticker = 0

	--- Duration of alpha fade. Set to -1 for no fading.
	mobj.alphaFuse = -1

	--- Frame flags added to copied frames (e.g. fullbright, additive).
	mobj.frameFlags = 0

	--- Automatically remove overlay if target becomes invalid.
	mobj.autoRemove = true

	--- Starting alpha value (fixed-point), default 1/3.
	mobj.alphaStart = FU / 3

	--- Ending alpha value (fixed-point), default fully transparent (0).
	mobj.alphaEnd = 0

	--- Optional palette translation string, nil if none.
	mobj.translation = nil
end, MT_FH_OVERLAY)

--- Updates overlay each tick to match target's appearance and handle fading.
---@param mobj heistOverlay_t
addHook("MobjThinker", function(mobj)
	-- Remove overlay if target is missing or invalid (and autoRemove enabled).
	if not mobj.target or not mobj.target.valid then
		if mobj.autoRemove then
			P_RemoveMobj(mobj)
			return
		end
	end

	---@type mobj_t
	local target = mobj.target

	if target then
		-- Copy all relevant visual properties from target.
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

		-- Move overlay to exactly match target's position.
		P_MoveOrigin(mobj, target.x, target.y, target.z)
	end

	-- Handle alpha fading if enabled.
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

--- Command to spawn an overlay on the player mobj, with optional customization parameters.
--- @param player player_t            # Player issuing the command.
--- @param translation string?        # Optional palette translation string.
--- @param alphaStart string?         # Optional start alpha (fixed-point or decimal string).
--- @param alphaEnd string?           # Optional end alpha (fixed-point or decimal string).
--- @param alphaFuse string?          # Optional fade duration in ticks.
COM_AddCommand("fh_overlay", function(player, translation, alphaStart, alphaEnd, alphaFuse)
	local target = player.mo
	if not target then return end

	local overlay = P_SpawnMobjFromMobj(target, 0, 0, 0, MT_FH_OVERLAY) --[[@as heistOverlay_t]]
	overlay.target = target

	-- Set overlay angle to player drawangle for players.
	if player.drawangle then
		overlay.angle = player.drawangle
	end

	overlay.translation = translation or nil
	overlay.alphaStart = tofixed(alphaStart) or (FU / 3)
	overlay.alphaEnd = tofixed(alphaEnd) or 0
	---@diagnostic disable-next-line: assign-type-mismatch
	overlay.alphaFuse = tonumber(alphaFuse) or TICRATE
	overlay.alpha = overlay.alphaStart
end)
