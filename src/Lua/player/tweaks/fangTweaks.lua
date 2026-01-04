for i = A, D do
	local state = freeslot("S_PLAY_FH_VERTICAL_POPGUN"..i)
	local data = states[state]

	data.sprite = SPR_PLAY
	data.frame = SPR2_MLEE
	data.tics = -1
	data.nextstate = state

	if i == A then continue end

	local lastState = _G["S_PLAY_FH_VERTICAL_POPGUN"..i-1]
	local lastStateData = states[lastState]

	lastStateData.nextstate = state
	lastStateData.tics = 2
end

states[S_PLAY_FH_VERTICAL_POPGUN0].action = function(mobj)
	S_StartSound(mobj, sfx_corkp)

	local cork = P_SpawnMobjFromMobj(
		mobj,
		0,
		0,
		(mobj.height / 2) - (mobjinfo[MT_CORK].height / 2),
		MT_CORK
	)

	if cork and cork.valid then
		cork.target = mobj

		local speed = FixedHypot(mobj.momx, mobj.momy)
		P_InstaThrust(cork, mobj.angle, speed + 24*FU)
		P_InstaThrust(cork, mobj.angle, speed + 24*FU)

		cork.spritexscale = 2*FU
		cork.spriteyscale = 2*FU
		cork.radius = $*2
		cork.height = $*2
		cork.momz = 2 * FU * P_MobjFlip(mobj)
		cork.flags = $ & ~MF_NOGRAVITY
		cork.angle = mobj.angle
	end
end

addHook("JumpSpinSpecial", function(player)
	if player.lastbuttons & BT_SPIN then return end
	if not FH:isMode() then return end
	if not player.mo then return end
	if player.mo.skin ~= "fang" then return end
	if player.pflags & PF_THOKKED then return end

	-- pop
	player.mo.state = S_PLAY_FH_VERTICAL_POPGUN0
	player.pflags = ($ & ~PF_BOUNCING)|PF_THOKKED
end)