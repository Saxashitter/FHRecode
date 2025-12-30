--- Makes the Mobj follow the target.
--- @param var1 fixed_t|nil
--- @param var2 fixed_t|nil
--- @param mobj mobj_t
function A_FH_Follow(mobj, var1, var2)
	if not mobj.target then return end
	if not mobj.target.valid then return end

	var1 = $ or 0
	var2 = $ or 0

	P_MoveOrigin(mobj, mobj.target.x, mobj.target.y, mobj.target.z + mobj.target.height/2 + var2)
	mobj.angle = mobj.target.angle
end