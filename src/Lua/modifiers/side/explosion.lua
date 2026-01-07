--- @type heistModifier_t
local modifier = setmetatable({}, FH:returnModifierMetatable())

freeslot("SPR_DEXP")

for i = A, R do
	local state = freeslot("S_FH_DELTARUNEEXPLOSION"..i)
	states[state].sprite = SPR_DEXP
	states[state].tics = 1
	states[state].frame = i

	if i == A then continue end

	local lastState = _G["S_FH_DELTARUNEEXPLOSION"..(i-1)]

	states[lastState].nextstate = state
end

sfxinfo[freeslot("sfx_fh_hit")].caption = "Frying pan."

freeslot("S_FH_PLAYER_EXPLOSIONPAIN1", "S_FH_PLAYER_EXPLOSIONPAIN2")

states[S_FH_PLAYER_EXPLOSIONPAIN1].tics = 1
states[S_FH_PLAYER_EXPLOSIONPAIN1].sprite = SPR_PLAY
states[S_FH_PLAYER_EXPLOSIONPAIN1].frame = SPR2_PAIN
states[S_FH_PLAYER_EXPLOSIONPAIN1].action = A_GhostMe
states[S_FH_PLAYER_EXPLOSIONPAIN1].nextstate = S_FH_PLAYER_EXPLOSIONPAIN1

states[S_FH_PLAYER_EXPLOSIONPAIN2].tics = 1
states[S_FH_PLAYER_EXPLOSIONPAIN2].sprite = SPR_PLAY
states[S_FH_PLAYER_EXPLOSIONPAIN2].frame = SPR2_DEAD
states[S_FH_PLAYER_EXPLOSIONPAIN2].action = A_GhostMe
states[S_FH_PLAYER_EXPLOSIONPAIN2].nextstate = S_FH_PLAYER_EXPLOSIONPAIN2

modifier.name = "Explosion"
modifier.description = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
modifier.type = "side"

local function spawnExplosion(player)
	local mobj = P_SpawnMobjFromMobj(player.mo, 0,0,0, MT_THOK)
	mobj.state = S_FH_DELTARUNEEXPLOSION0
	mobj.scale = $ * 2
	mobj.destscale = mobj.scale

	S_StartSound(player.mo, sfx_s3k4e)
	S_StartSound(player.mo, sfx_s3k5d)
end

local function launchExplodedPlayerUp(player, normal)
	local mo = player.mo

	local velAngle = R_PointToAngle2(0, 0, mo.momx, mo.momy)

	-- Reflect angle across the wall normal
	local newAngle = normal*2 - velAngle

	-- Current velocity angle & speed
	local speed = FixedHypot(mo.momx, mo.momy)
	if speed == 0 then return end

	-- Apply bounce (with slight damping)
	local bounce = FixedMul(speed, FU*7/8)
	mo.momx = FixedDiv(FixedMul(bounce, cos(newAngle)), (FU / 10) * 12)
	mo.momy =  FixedDiv(FixedMul(bounce, sin(newAngle)), (FU / 10) * 12)

	P_SetObjectMomZ(mo, 20 * mo.scale)

	-- Swap pain state so it animates
	mo.state = S_FH_PLAYER_EXPLOSIONPAIN2
	spawnExplosion(mo.player)
end

--- @param player player_t
function modifier:playerDamage(player, inflictor, target)
	spawnExplosion(player)

	player.mo.momx = $ * 25
	player.mo.momy = $ * 25
	player.mo.momz = $
	player.mo.state = S_FH_PLAYER_EXPLOSIONPAIN1
	player.mo.fh_bounceOnFloor = true

	if target and target.valid then
		player.mo.fh_target = target
	end
end

function modifier:playerUpdate(player)
	if not player.mo then return end
	if not player.mo.health then return end

	if player.mo.state == S_FH_PLAYER_EXPLOSIONPAIN2 then
		player.mo.rollangle = $ + ANG1 * 45
		player.mo.fh_rotated = true
	elseif player.mo.fh_rotated then
		player.mo.fh_rotated = nil
		player.mo.rollangle = 0
	end

	if not player.mo.fh_target or not player.mo.fh_target.valid then
		player.mo.fh_target = nil
	end

	if player.mo.state == S_FH_PLAYER_EXPLOSIONPAIN1 or player.mo.state == S_FH_PLAYER_EXPLOSIONPAIN2 then
		player.pflags = $|PF_FULLSTASIS

		---@diagnostic disable-next-line: missing-parameter
		searchBlockmap(
			"objects",
			function(_, mobj)
				if not mobj.valid then return end
				if not mobj.health then return end
				if mobj.flags & (MF_ENEMY|MF_MONITOR) == 0 and mobj.type ~= MT_PLAYER then return end
				if player.mo.fh_target == mobj then return end
				if mobj.z > player.mo.z + player.mo.height then return end
				if player.mo.z > mobj.z + mobj.height then return end

				if P_DamageMobj(mobj, player.mo, player.mo.fh_target) then
					local angle = R_PointToAngle2(mobj.x, mobj.y, player.mo.x, player.mo.y) + ANGLE_90

					launchExplodedPlayerUp(player, angle)
					S_StartSound(player.mo, sfx_fh_hit)
					S_StartSound(mobj, sfx_fh_hit)
				end
			end,
			player.mo,
			player.mo.x - player.mo.radius * 2,
			player.mo.x + player.mo.radius * 2,
			player.mo.y - player.mo.radius * 2,
			player.mo.y + player.mo.radius * 2
		)
	end
end

--- @param mo mobj_t
--- @param line line_t
addHook("MobjMoveBlocked", function(mo, _, line)
	if not FH:isMode() then return end
	if not FH:isModifierActive(modifier) then return end

	if not mo.valid then return end
	if not mo.health then return end
	if not mo.player then return end
	if mo.state ~= S_FH_PLAYER_EXPLOSIONPAIN1 and mo.state ~= S_FH_PLAYER_EXPLOSIONPAIN2 then return end
	if not line or not line.valid then return end

	-- Wall normal (perpendicular to the line)
	local normal = R_PointToAngle2(line.v1.x, line.v1.y, line.v2.x, line.v2.y)

	launchExplodedPlayerUp(mo.player, normal)
end, MT_PLAYER)

return FH:registerModifier(modifier)