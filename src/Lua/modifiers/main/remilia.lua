-- ======================================================
-- MODIFIER SETUP
-- ======================================================

--- @type heistModifier_t
local modifier = setmetatable({}, FH:returnModifierMetatable())

modifier.name = "Remilia Scarlet"
modifier.description = "It's gonna be a long night..."
modifier.type = "main"
modifier.music = "SPFTDP"
modifier.timesUpMusic = "FH_OVF"
modifier.timesUpStart = 38400 * TICRATE / MUSICRATE

modifier.chaseDelay = TICRATE

-- ======================================================
-- FREESLOTS / MOBJ + STATE DEFINITIONS
-- ======================================================

freeslot(
	"MT_FH_REMILIA_CHASER",
	"MT_FH_BULLET",

	"S_FH_REMILIA_CHASER",
	"S_FH_REGULARBULLET",
	"S_FH_COOLERLOOKINGBULLET",
	"S_FH_BEAMBULLET",
	"S_FH_REMIBAT",

	"sfx_rm_frd",
	"sfx_rm_sh1",
	"sfx_rm_sh2",
	"sfx_rm_stn",
	"sfx_rm_trg"
)

mobjinfo[MT_FH_REMILIA_CHASER].radius = 48 * FU
mobjinfo[MT_FH_REMILIA_CHASER].height = 64 * FU
mobjinfo[MT_FH_REMILIA_CHASER].flags =
	MF_NOCLIP | MF_NOCLIPHEIGHT | MF_NOGRAVITY | MF_SPECIAL
mobjinfo[MT_FH_REMILIA_CHASER].spawnstate = S_FH_REMILIA_CHASER

mobjinfo[MT_FH_BULLET].radius = 8 * FU
mobjinfo[MT_FH_BULLET].height = 16 * FU
mobjinfo[MT_FH_BULLET].flags = MF_NOGRAVITY | MF_MISSILE
mobjinfo[MT_FH_BULLET].spawnstate = S_FH_REGULARBULLET
mobjinfo[MT_FH_BULLET].speed = 8 * FU

states[S_FH_REMILIA_CHASER] = {
	sprite = freeslot("SPR_REMI"),
	frame = A,
	tics = -1,
	nextstate = S_FH_REMILIA_CHASER
}

states[S_FH_REGULARBULLET] = {
	sprite = freeslot("SPR_RBL2"),
	frame = FF_FULLBRIGHT,
	action = A_GhostMe,
	tics = -1
}

states[S_FH_COOLERLOOKINGBULLET] = {
	sprite = freeslot("SPR_RBL1"),
	frame = FF_FULLBRIGHT,
	action = A_GhostMe,
	tics = -1
}

states[S_FH_BEAMBULLET] = {
	sprite = freeslot("SPR_RBEM"),
	frame = FF_FULLBRIGHT,
	action = A_GhostMe
}

states[S_FH_REMIBAT] = {
	sprite = freeslot("SPR_RBAT"),
	frame = FF_FULLBRIGHT|FF_ANIMATE,
	action = A_GhostMe,
	var1 = C,
	var2 = 3,
	tics = -1
}

sfxinfo[sfx_rm_frd].caption = "You are no longer being targetted!"
sfxinfo[sfx_rm_sh1].caption = "Shot"
sfxinfo[sfx_rm_sh2].caption = "Shot"
sfxinfo[sfx_rm_stn].caption = "Stunned"
sfxinfo[sfx_rm_trg].caption = "You are being targetted."

-- ======================================================
-- AI HELPER FUNCTIONS
-- ======================================================

--- @param player player_t
local function playerIsValid(player)
	return player and player.valid and player.mo and player.mo.valid and player.mo.health and player.hr and not player.hr.qualified and not player.hr.downed
end

local function getClosestPlayer(chaser)
	local target, dist

	for player in players.iterate do
		if not playerIsValid(player) then continue end

		local d = R_PointToDist2(
			0, chaser.z,
			R_PointToDist2(chaser.x, chaser.y, player.mo.x, player.mo.y),
			player.mo.z
		)

		if not target or d < dist then
			target = player
			dist = d
		end
	end

	return target, dist
end

local function setTarget(chaser, target)
	if (chaser.tracer and chaser.tracer.valid and chaser.tracer ~= target and playerIsValid(chaser.tracer.player)) then
		S_StartSound(nil, sfx_rm_frd, chaser.tracer.player)
	end
	S_StartSound(nil, sfx_rm_trg, target.player)

	chaser.tracer = target
	modifier:setState(chaser, "bigBulletShoot")
end

local function chaserMovement(chaser, target)
	if not modifier:canTarget(chaser) then return end
	if not chaser.tracer then return end
	if not chaser.tracer.valid then return end
	if not playerIsValid(chaser.tracer.player) then return end
	if not modifier:canMove(chaser) then return end

	local angle = R_PointToAngle2(chaser.x, chaser.y, chaser.tracer.x, chaser.tracer.y)
	local distXY = 128 * FU
	local flyZ = 64 * FU -- direction vector to player (center-to-center)
	local dx = (chaser.tracer.x + P_ReturnThrustX(nil, angle, -distXY)) - chaser.x
	local dy = (chaser.tracer.y + P_ReturnThrustY(nil, angle, -distXY)) - chaser.y
	local dz = ((chaser.tracer.z + chaser.tracer.height/2) + flyZ) - (chaser.z + chaser.height/2)
	local dist = FH:pointTo3DDist(0, 0, 0, dx, dy, dz)

	if dist > 0 then -- normalize
		local ndx = FixedDiv(dx, dist)
		local ndy = FixedDiv(dy, dist)
		local ndz = FixedDiv(dz, dist)
		local maxSpeed = 24 * (dist > 0 and FixedDiv(dist, 128 * FU) or 0)
		local desiredMomX = FixedMul(ndx, maxSpeed) local desiredMomY = FixedMul(ndy, maxSpeed)
		local desiredMomZ = FixedMul(ndz, maxSpeed / 6) -- if mobj is moving backwards from tracer, divide momentum values
		local curDist = FH:pointTo3DDist(
			chaser.x,
			chaser.y,
			0, -- remiliaChaser.z + remiliaChaser.height / 2,
			chaser.tracer.x,
			chaser.tracer.y,
			0 -- remiliaChaser.tracer.z + remiliaChaser.height / 2
		)
		local futureDist = FH:pointTo3DDist(
			chaser.x + desiredMomX,
			chaser.y + desiredMomY,
			0, -- remiliaChaser.z + remiliaChaser.height / 2 + desiredMomZ,
			chaser.tracer.x,
			chaser.tracer.y,
			0 -- remiliaChaser.tracer.z + remiliaChaser.height / 2
		)

		if curDist < futureDist then
			local mul = FU / 7
			desiredMomX = FixedMul($, mul)
			desiredMomY = FixedMul($, mul)
			-- desiredMomZ = FixedMul($, mul)
		end

		chaser.momx = desiredMomX
		chaser.momy = desiredMomY
		chaser.momz = desiredMomZ
	end

	local friction = FU * 10 / 11
	chaser.momx = FixedMul($, friction)
	chaser.momy = FixedMul($, friction)
	chaser.momz = FixedMul($, friction)
end

-- ======================================================
-- STATE SYSTEM CORE
-- ======================================================

function modifier:setState(chaser, stateName)
	chaser._state = stateName
	self.attacks[stateName].init(chaser, chaser.tracer)
end

function modifier:updateState(chaser)
	local state = self.attacks[chaser._state]
	if state then
		state.update(chaser, chaser.tracer)
	end
end

function modifier:canTarget(chaser)
	local state = self.attacks[chaser._state]
	return not state or state.canTarget ~= false
end

function modifier:canMove(chaser)
	local state = self.attacks[chaser._state]
	return not state or state.canMove ~= false
end

modifier.attacks = {
	shoot = {
		canTarget = true,
		canMove = true,

		--- @param chaser mobj_t
		--- @param target mobj_t
		init = function(chaser, target)
			chaser.shotDelay = 3
			chaser.shotTime = 3 * 20
			chaser.switchDelay = 2 * TICRATE
		end,

		--- @param chaser mobj_t
		--- @param target mobj_t
		update = function(chaser, target)
			-- bullet prediction code
			-- plan for attack:
				-- bullets can be weaved easily by moving to the side, moving directly forward = hurt

			if not chaser.shotTime then
				chaser.switchDelay = $ - 1

				if not chaser.switchDelay then
					modifier:setState(chaser, "bigBulletShoot")
				end

				return
			end
			chaser.shotTime = $ - 1

			if chaser.shotDelay then
				chaser.shotDelay = $ - 1
				return
			end
			chaser.shotDelay = 3

			S_StopSoundByID(chaser, sfx_rm_sh2)
			S_StartSound(chaser, sfx_rm_sh2)

			for i = 1, 3 do
				local random = 128 * FU
				local randomZ = 32 * FU
				local momMult = FU * 35

				local angle = R_PointToAngle2(chaser.x, chaser.y, target.x, target.y)
				local randomXY = FH:fixedRandom(-240 * FU, 240 * FU)

				local bullet = modifier:bulletToPoint(chaser, {
					x = target.x + FixedMul(randomXY, cos(angle - ANGLE_90)) + FixedMul(target.momx, momMult),
					y = target.y + FixedMul(randomXY, sin(angle - ANGLE_90)) + FixedMul(target.momy, momMult),
					z = target.z + target.height / 2 + FH:fixedRandom(0, randomZ) + FixedMul(target.momz, momMult)
				}, mobjinfo[MT_FH_BULLET].speed + FixedMul(FH:pointTo3DDist(0,0,0, target.momx, target.momy, target.momz), (FU * 6) / 6))

				if bullet and bullet.valid then
					bullet.momx = $ + FixedMul(randomXY, cos(angle - ANGLE_90)) / 100
					bullet.momy = $ + FixedMul(randomXY, sin(angle - ANGLE_90)) / 100
					bullet.scale = $ * 5 / 4
					bullet.destscale = bullet.scale

					bullet.fh_playerdamage = 8 * FU
					bullet.fh_playerblockdamage = FU / 10
					bullet.fh_blockbreakmult = FU * 3 / 2
				end
			end
		end
	},
	bigBulletShoot = {
		canTarget = true,
		canMove = true,

		--- @param chaser mobj_t
		--- @param target mobj_t
		init = function(chaser, target)
			chaser.shotDelay = 6
			chaser.shotTime = 6 * 10
			chaser.switchDelay = 2 * TICRATE
		end,

		--- @param chaser mobj_t
		--- @param target mobj_t
		update = function(chaser, target)
			-- bullet prediction code
			-- plan for attack:
				-- youd have to stop and do a 180 to dodge the bullets
				-- bullets big

			if not chaser.shotTime then
				chaser.switchDelay = $ - 1

				if not chaser.switchDelay then
					modifier:setState(chaser, "shoot")
				end

				return
			end
			chaser.shotTime = $ - 1

			if chaser.shotDelay then
				chaser.shotDelay = $ - 1
				return
			end
			chaser.shotDelay = 6

			S_StopSoundByID(chaser, sfx_rm_sh1)
			S_StartSound(chaser, sfx_rm_sh1)

			for i = 1, 1 do
				local speed = 16 * FU
				local random = 128 * FU
				local randomZ = 32 * FU
				local momMult = FU * 30

				local angle = R_PointToAngle2(chaser.x, chaser.y, target.x, target.y)
				local randomXY = FH:fixedRandom(-240 * FU, 240 * FU)

				local bullet = modifier:bulletToPoint(chaser, {
					x = target.x + FixedMul(target.momx, momMult),
					y = target.y + FixedMul(target.momy, momMult),
					z = target.z + target.height / 2
				}, speed + FH:pointTo3DDist(0,0,0, target.momx, target.momy, target.momz))

				if bullet and bullet.valid then
					bullet.scale = $ * 2
					bullet.destscale = bullet.scale

					bullet.fh_playerdamage = 16 * FU
					bullet.fh_playerblockdamage = FU / 7
					bullet.fh_blockbreakmult = FU * 3 / 2
				end
			end
		end
	},
	stunned = {
		canTarget = false,
		canMove = false,
		--- @param chaser mobj_t
		--- @param target mobj_t
		init = function(chaser, target)
			chaser.stunTime = 5 * TICRATE -- duration in tics (0.5 sec)
		end,

		--- @param chaser mobj_t
		--- @param target mobj_t
		update = function(chaser, target)
			-- freeze movement
			chaser.momx = 0
			chaser.momy = 0
			chaser.momz = 0

			-- countdown
			chaser.stunTime = $ - 1
			if chaser.stunTime <= 0 then
				chaser.stunTime = nil
				local target = getClosestPlayer(chaser)
				if target then
					setTarget(chaser, target.mo)
				else
					chaser.tracer = nil
				end
			end
		end
	}
}

-- ======================================================
-- BULLET UTILITY
-- ======================================================

function modifier:bulletToPoint(chaser, point, speed)
	local m = P_SpawnMobjFromMobj(
		chaser, 0, 0,
		chaser.height/2 - mobjinfo[MT_FH_BULLET].height/2,
		MT_FH_BULLET
	)
	if not m or not m.valid then return end

	local dx = point.x - m.x
	local dy = point.y - m.y
	local dz = point.z - (m.z + m.height/2)

	local mag = FH:pointTo3DDist(0,0,0, dx,dy,dz)
	if mag == 0 then return m end

	dx,dy,dz = FixedDiv(dx,mag), FixedDiv(dy,mag), FixedDiv(dz,mag)
	speed = speed or m.info.speed

	m.momx = FixedMul(speed, dx)
	m.momy = FixedMul(speed, dy)
	m.momz = FixedMul(speed, dz)

	-- randomize frame
	m.frame = ($ & ~FF_FRAMEMASK)|P_RandomRange(A, P)

	return m
end

addHook("MobjThinker", function(chaser)
	if not chaser.valid then return end
	if FHR.remiliaChaserDelay then return end

	if modifier:canTarget(chaser) then
		if not (chaser.tracer and chaser.tracer.valid and playerIsValid(chaser.tracer.player)) then
			local target = getClosestPlayer(chaser)
			if target then
				setTarget(chaser, target.mo)
			else
				chaser.tracer = nil
			end
		end
	end

	if modifier:canMove(chaser) then
		chaserMovement(chaser, chaser.tracer)
	end

	modifier:updateState(chaser)
end, MT_FH_REMILIA_CHASER)

-- ======================================================
-- TOUCH SPECIAL (STUN)
-- ======================================================

addHook("TouchSpecial", function(chaser, victim)
	if chaser.hurtTime and leveltime - chaser.hurtTime < 8*TICRATE then
		return true
	end

	if not P_PlayerCanDamage(victim.player, chaser)
	and not victim.fh_instashield then
		return true
	end

	victim.momx = -$
	victim.momy = -$

	local overlay = P_SpawnMobjFromMobj(chaser, 0,0,0, MT_FH_OVERLAY)
	overlay.target = chaser
	overlay.translation = "FH_AllRed"
	overlay.alphaFuse = 10
	S_StartSound(chaser, sfx_rm_stn)

	chaser.hurtTime = leveltime
	modifier:setState(chaser, "stunned")

	return true
end, MT_FH_REMILIA_CHASER)

-- ======================================================
-- MODIFIER LIFECYCLE
-- ======================================================

function modifier:init()
	local gametype = FH:isMode()
	local x,y,z

	for mt in mapthings.iterate do
		if mt.type == gametype.signpostThing then
			x,y,z = FH:getMapthingWorldPosition(mt)
		end
	end

	P_SetupLevelSky(87)
	for player in players.iterate do
		P_SetSkyboxMobj(nil, player)
	end

	FHR.remiliaChaser = P_SpawnMobj(x,y,z, MT_FH_REMILIA_CHASER)
	FHR.remiliaChaserDelay = self.chaseDelay
end

function modifier:update()
	if FHR.remiliaChaserDelay then
		FHR.remiliaChaserDelay = $ - 1
	end
end

function modifier:finish()
	if FHR.remiliaChaser and FHR.remiliaChaser.valid then
		P_RemoveMobj(FHR.remiliaChaser)
	end
	FHR.remiliaChaser = nil
end

return FH:registerModifier(modifier)