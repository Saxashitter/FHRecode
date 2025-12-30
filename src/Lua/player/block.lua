--- @class mobj_t
--- If this isn't nil, the mobj is blocking.
--- @field fh_block mobj_t|nil

freeslot("MT_FH_BLOCK")
freeslot("SPR_LOSH")

mobjinfo[MT_FH_BLOCK].radius = 16 * FU
mobjinfo[MT_FH_BLOCK].height = 32 * FU
mobjinfo[MT_FH_BLOCK].flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOBLOCKMAP|MF_NOGRAVITY
mobjinfo[MT_FH_BLOCK].dispoffset = 1

for i = A, H do
	freeslot("S_FH_BLOCK"..i)
end
mobjinfo[MT_FH_BLOCK].spawnstate = S_FH_BLOCK0
for i = A, H do
	--- @type statenum_t
	local state = _G["S_FH_BLOCK"..i]

	states[state].sprite = SPR_LOSH
	states[state].frame = i|FF_FULLBRIGHT
	states[state].action = function(mobj)
		if not mobj.target then P_RemoveMobj(mobj) return end
		if not mobj.target.valid then P_RemoveMobj(mobj) return end

		if not S_SoundPlaying(mobj.target, sfx_s25d) then
			S_StartSoundAtVolume(mobj.target, sfx_s25d, 25)
		end

		P_SpawnGhostMobj(mobj)
		A_FH_Follow(mobj)
	end
	states[state].tics = 1
	
	if i == H then
		states[state].nextstate = S_FH_BLOCK0
		continue
	end
	states[state].nextstate = state+1
end

addHook("MobjRemoved", function(mobj)
	if mobj.target and mobj.target.valid and mobj.target.fh_block == mobj then
		mobj.target.fh_block = nil
	end
end, MT_FH_BLOCK)

function FH:useBlock(mobj)
	local block = P_SpawnMobjFromMobj(mobj, 0,0,0, MT_FH_BLOCK)

	block.target = mobj
	---@diagnostic disable-next-line: assign-type-mismatch
	block.color = skincolors[mobj.color].invcolor
	block.destscale = mobj.destscale
	block.scale = mobj.scale

	S_StartSoundAtVolume(mobj, sfx_kc52, 50)
	S_StartSoundAtVolume(mobj, sfx_kc54, 100)

	mobj.fh_block = block
end

function FH:stopBlock(mobj)
	if not mobj.fh_block then return end

	S_StartSound(mobj, sfx_kc55)
	S_StartSound(mobj, sfx_kc59)
	S_StartSound(mobj, sfx_s25b)

	local block = mobj.fh_block
	P_RemoveMobj(block)

	-- TODO: effects
end
