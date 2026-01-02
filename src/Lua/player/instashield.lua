--- @class mobj_t
--- If this isn't nil, the mobj has an insta-shield active.
--- @field fh_instashield mobj_t|nil

--- Runs the hit-scan and follow logic for the insta-shield.
--- Returns a table of mobjs hit and the count.
--- @param mobj mobj_t
--- @param xyRange fixed_t
--- @param zRange fixed_t
--- @return table
--- @return number
function A_FH_InstaShieldTicker(mobj, xyRange, zRange)
	if not mobj.target then
		return {}, 0
	end
	if not mobj.target.valid then
		return {}, 0
	end

	A_FH_Follow(mobj)

	local attacked = {}

	-- Scale ranges by player scale
	xyRange = FixedMul(xyRange, mobj.target.scale)
	zRange  = FixedMul(zRange,  mobj.target.scale)

	local ox, oy, oz = mobj.target.x, mobj.target.y, mobj.target.z + mobj.target.height / 2
	local count = 1
	searchBlockmap(
		"objects",
		function(_, foundMobj)
			count = $ + 1
	
			if not foundMobj
			or not foundMobj.valid
			or not foundMobj.health then
				return
			end
			
			if foundMobj == mobj.target then
				return
			end

			if foundMobj.flags & (MF_ENEMY|MF_MONITOR|MF_BOSS) == 0
			and foundMobj.type ~= MT_PLAYER then
				return
			end

			local xyDist = R_PointToDist2(ox, oy, foundMobj.x, foundMobj.y)
			local zDist = abs(oz - (foundMobj.z + foundMobj.height / 2))
			
			-- Oval hit check
			local nx = FixedDiv(xyDist, xyRange)
			local nz = FixedDiv(zDist,  zRange)
			
			if FixedMul(nx, nx) + FixedMul(nz, nz) > FRACUNIT then
				return
			end

			if foundMobj.fh_instashield then
				FH:knockbackMobj(foundMobj, mobj.target)
				FH:knockbackMobj(mobj.target, foundMobj)

				S_StartSound(foundMobj,   sfx_dmpain)
				S_StartSound(foundMobj,   sfx_mspogo)
				S_StartSound(mobj.target, sfx_dmpain)
				S_StartSound(mobj.target, sfx_mspogo)
	
				P_RemoveMobj(mobj)
				P_RemoveMobj(foundMobj.fh_instashield)

				return true
			end
	
			if P_DamageMobj(foundMobj, mobj, mobj.target) then
				attacked[#attacked + 1] = foundMobj
			end
		end,
		mobj,
		ox - (xyRange * 2), ox + (xyRange * 2),
		oy - (xyRange * 2), oy + (xyRange * 2)
	)

	return attacked, #attacked
end

-- The insta-shield ticker, but with some extra knockback.
--- @param mobj mobj_t
--- @param xyRange fixed_t
--- @param zRange fixed_t
function A_FH_PlayerInstaShieldTicker(mobj, xyRange, zRange)
	local attacked, len = A_FH_InstaShieldTicker(mobj, xyRange, zRange)
	
	if len == 0 then
		return
	end

	FH:reflectMobj(mobj.target, attacked[1])

	-- cap speed
	local vx = mobj.target.momx
	local vy = mobj.target.momy
	local vz = mobj.target.momz
	local spd = R_PointToDist2(0,0,R_PointToDist2(0,0,vx,vy),vz)
	local cap = 20 * mobj.scale

	if spd > cap then
		local div = FixedDiv(cap, spd)

		mobj.target.momx = FixedMul($, div)
		mobj.target.momy = FixedMul($, div)
		mobj.target.momz = FixedMul($, div)
	end

	P_RemoveMobj(mobj)
end

freeslot("SPR_INSH")
freeslot("MT_FH_INSTASHIELD")

-- i dont see a reason to make 1000 manual states when for loops exist

--- @type UINT32
for i = A, G do
	local state = freeslot("S_FH_INSTASHIELD"..i)
end

--- @type UINT32
for i = A, G do
	local state = _G["S_FH_INSTASHIELD"..i]
	
	---@diagnostic disable-next-line: missing-fields
	states[state].sprite = SPR_INSH
	states[state].frame = i
	states[state].action = A_FH_PlayerInstaShieldTicker
	states[state].var1 = 128 * FU
	states[state].var2 = 128 * FU
	states[state].tics = 1
	states[state].nextstate = S_NULL

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