--- @class mobj_t
--- If this isn't nil, the mobj has an insta-shield active.
--- @field fh_instashield mobj_t|nil

--- Runs the hit-scan for the insta-shield (per-player).
--- Returns a table of mobjs hit and the count.
--- @param mo mobj_t
--- @param xyRange fixed_t
--- @param zRange fixed_t
--- @return table
--- @return number
function FH:instaShieldHitScan(mo, xyRange, zRange)
	if not mo or not mo.valid then
		return {}, 0
	end

	local attacked = {}

	-- Scale ranges by player scale
	xyRange = FixedMul(xyRange, mo.scale)
	zRange  = FixedMul(zRange,  mo.scale)

	local ox, oy, oz = mo.x, mo.y, mo.z

	searchBlockmap(
		"objects",
		function(_, foundMobj)
			if not foundMobj
			or not foundMobj.valid
			or not foundMobj.health then
				return
			end

			if foundMobj == mo then
				return
			end

			if foundMobj.flags & (MF_ENEMY|MF_MONITOR|MF_BOSS) == 0
			and foundMobj.type ~= MT_PLAYER then
				return
			end

			local horiz = xyRange + foundMobj.radius
			local vert  = zRange  + foundMobj.height / 2

			local d = R_PointToDist2(ox, oy, foundMobj.x, foundMobj.y)

			local z1 = oz
			local z2 = foundMobj.z + foundMobj.height / 2
			local dz = z2 - z1

			-- Normalize axes
			local n  = FixedDiv(d,  horiz)
			local nz = FixedDiv(dz, vert)

			-- Ellipsoid distance check
			if FixedMul(n, n) + FixedMul(nz, nz) > FRACUNIT then
				return
			end

			if P_DamageMobj(foundMobj, mo, mo) then
				attacked[#attacked + 1] = foundMobj
			end
		end,
		mo,
		ox - xyRange * 2, ox + xyRange * 2,
		oy - xyRange * 2, oy + xyRange * 2
	)

	return attacked, #attacked
end

freeslot("SPR_INSH")
freeslot("MT_FH_INSTASHIELD")

-- i dont see a reason to make 1000 manual states when for loops exist
for i = A, G do
	local state = freeslot("S_FH_INSTASHIELD"..i)
end
for i = A, G do
	local state = _G["S_FH_INSTASHIELD"..i]
	
	states[state] = {
		sprite = SPR_INSH,
		---@diagnostic disable-next-line: assign-type-mismatch
		frame = i, -- TODO: frame stuff
		tics = 1,
		---@diagnostic disable-next-line: assign-type-mismatch
		action = nil,
		var1 = 0,
		var2 = 0,
		nextstate = S_NULL
	}

	if i >= G then break end

	local nextstate = _G["S_FH_INSTASHIELD"..i+1]
	states[state].nextstate = nextstate
end

---@diagnostic disable-next-line: missing-fields
mobjinfo[MT_FH_INSTASHIELD] = {
	spawnstate = S_INVISIBLE,
	radius = FU,
	height = FU,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOGRAVITY
}

addHook("MobjRemoved", function(mobj)
	if mobj.target and mobj.target.valid and mobj.target.fh_instashield == mobj then
		mobj.target.fh_instashield = nil
	end
end, MT_FH_INSTASHIELD)

--- Spawns the insta-shield AND does it's effects. It's recommended to do this unless you are applying your own or changing the behavior.
function FH:useInstaShield(mobj)
	local instaShield = P_SpawnMobjFromMobj(mobj, 0, 0, mobj.height/2, MT_FH_INSTASHIELD)

	instaShield.target = mobj
	instaShield.state = S_FH_INSTASHIELD0

	mobj.fh_instashield = instaShield
	S_StartSound(mobj, sfx_s3k64)

	return instaShield
end