--- @class mobj_t
--- If this isn't nil, the mobj has an insta-shield active.
--- @field fh_instashield mobj_t|nil

--- Follows the target and attacks around it. If the mobj hits anybody, it'll damage them, setting the source of the attack to the mobj.
--- @param mobj mobj_t
--- The range of the attack on the horizontal axis.
--- @param var1 fixed_t
--- The range of the attack on the vertical axis.
--- @param var2 fixed_t
function A_FH_InstaShieldTicker(mobj, var1, var2)
	if not mobj.target then P_RemoveMobj(mobj) return end
	if not mobj.target.valid then P_RemoveMobj(mobj) return end

	local attacked = {}

	var1 = FixedMul($, mobj.scale)
	var2 = FixedMul($, mobj.scale)

	A_FH_Follow(mobj)

	searchBlockmap("objects", function(_, foundMobj)
		if not foundMobj then return end
		if not foundMobj.valid then return end
		if not foundMobj.health then return end
		if foundMobj.flags & MF_ENEMY|MF_MONITOR|MF_BOSS == 0 and foundMobj.type ~= MT_PLAYER then return end
		if foundMobj == mobj.target then return end

		local horiz = var1 + foundMobj.radius
		local vert = var2 + foundMobj.height/2

		local d = R_PointToDist2(mobj.x, mobj.y, foundMobj.x, foundMobj.y)

		local z1 = mobj.z
		local z2 = foundMobj.z + foundMobj.height/2
		local dz = z2 - z1

		-- Normalize each axis
		local n = FixedDiv(d, horiz)
		local nz = FixedDiv(dz, vert)

		-- Ellipsoid check
		local dist = FixedMul(n, n) + FixedMul(nz, nz)

		if dist > FRACUNIT then
			return
		end

		if P_DamageMobj(foundMobj, mobj, mobj.target) then
			attacked[#attacked + 1] = foundMobj
		end
	end, mobj, mobj.x - var1 * 2, mobj.x + var1 * 2, mobj.y - var1 * 2, mobj.y + var1 * 2)

	return attacked, #attacked
end

--- An extension for A_FH_InstaShieldTicker, but with some bounce.
--- Follows the target and attacks around it. If the mobj hits anybody, it'll damage them, setting the source of the attack to the mobj.
--- @param mobj mobj_t
--- The range of the attack on the horizontal axis.
--- @param var1 fixed_t
--- The range of the attack on the vertical axis.
--- @param var2 fixed_t
function A_FH_PlayerInstaShieldTicker(mobj, var1, var2)
	local attacked, len = A_FH_InstaShieldTicker(mobj, var1, var2)
	if not attacked or len == 0 then return end
	if P_IsObjectOnGround(mobj) then return end

	local player = mobj.target
	if not player or not player.valid then return end

	FH:knockbackMobj(player, attacked[1])

	for _, mo in ipairs(attacked) do
		if not (mo.type == MT_PLAYER and mo.player and mo.player.heistRound and mo.player.heistRound.downed) then
			continue
		end

		FH:knockbackMobj(mo, player)
	end

	-- local angle = R_PointToAngle2(0,0,sumx,sumy)
	-- local zangle = R_PointToAngle2(0,0,FixedHypot(sumx,sumy),sumz)
	-- local speed = R_PointToDist2(0, 0, FixedHypot(player.momx, player.momy), player.momz)

	-- player.momx = P_ReturnThrustX(mobj, angle, FixedMul(-speed, cos(zangle)))
	-- player.momy = P_ReturnThrustY(mobj, angle, FixedMul(-speed, cos(zangle)))
	-- player.momz = FixedMul(-speed, sin(zangle))
end

freeslot("SPR_INSH")
freeslot("MT_FH_INSTASHIELD")

-- i dont see a reason to make 1000 manual states when for loops exist
for i = A, G do
	local state = freeslot("S_FH_INSTASHIELD"..i)
end
for i = A, G do
	local state = _G["S_FH_INSTASHIELD"..i]
	local action = A_FH_PlayerInstaShieldTicker

	if i <= D then
		action = A_FH_Follow
	end
	if i == D+1 then
		action = function(mobj, var1, var2)
			if not mobj.target then return end
			if not mobj.target.valid then return end

			S_StartSound(mobj.target, sfx_s3k9c)
			S_StartSound(mobj.target, sfx_s3k42)

			A_FH_PlayerInstaShieldTicker(mobj, var1, var2)
		end
	end
	
	states[state] = {
		sprite = SPR_INSH,
		---@diagnostic disable-next-line: assign-type-mismatch
		frame = i, -- TODO: frame stuff
		tics = 1,
		action = action,
		var1 = 150 * FU,
		var2 = 150 * FU,
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