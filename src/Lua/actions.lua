--- Makes the Mobj follow the target.
--- @param mobj mobj_t
function A_FH_Follow(mobj)
	if not mobj.target then return end
	if not mobj.target.valid then return end

	P_MoveOrigin(mobj, mobj.target.x, mobj.target.y, mobj.target.z + mobj.target.height / 2)
	mobj.angle = mobj.target.angle

	mobj.eflags = $ & ~MFE_VERTICALFLIP
end