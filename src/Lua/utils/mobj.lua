--- @param target mobj_t
--- @param point table
--- @param minSpeed fixed_t|nil
function FH:knockbackMobj(target, point, minSpeed)
	local tz = target.z + target.height / 2
	local pz = point.z + point.height / 2
	local speed = max(R_PointToDist2(0, 0, R_PointToDist2(0, 0, target.momx, target.momy), target.momz), minSpeed or 0)
	local dist = R_PointToDist2(target.x, target.y, point.x, point.y)
	local angle = R_PointToAngle2(target.x, target.y, point.x, point.y)
	local aiming = R_PointToAngle2(0, 0, dist, pz - tz)

	P_InstaThrust(target, angle, -FixedMul(speed, cos(aiming)))
	---@diagnostic disable-next-line: assign-type-mismatch
	target.momz = -FixedMul(speed, sin(aiming))
end

--- Reflects target momentum off a point (shield-style)
--- @param target mobj_t
--- @param point table {x,y,z}
--- @param speedScale fixed_t|nil
function FH:reflectMobj(target, point, speedScale)
	speedScale = speedScale or FRACUNIT

	-- Incoming velocity
	local vx, vy, vz = target.momx, target.momy, target.momz

	-- Normal direction (from point to target)
	local nx = target.x - point.x
	local ny = target.y - point.y
	local nz = target.z + target.height / 2 - point.z + (point.height or 0) / 2

	local nlen = R_PointToDist2(0, 0, R_PointToDist2(0, 0, nx, ny), nz)
	if nlen == 0 then return end

	-- Normalize normal
	nx = FixedDiv(nx, nlen)
	ny = FixedDiv(ny, nlen)
	nz = FixedDiv(nz, nlen)

	-- Dot product
	local dot =
		FixedMul(vx, nx) +
		FixedMul(vy, ny) +
		FixedMul(vz, nz)

	-- Reflection
	target.momx = FixedMul(vx - FixedMul(2*dot, nx), speedScale)
	target.momy = FixedMul(vy - FixedMul(2*dot, ny), speedScale)
	target.momz = FixedMul(vz - FixedMul(2*dot, nz), speedScale)
end