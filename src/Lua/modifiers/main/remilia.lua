--- @type heistModifier_t
local modifier = setmetatable({}, FH:returnModifierMetatable())

modifier.name = "Remilia Scarlet"
modifier.description = "It's gonna be a long night..."
modifier.type = "main"
modifier.music = "SPFTDP"

-- =======================
-- Attack states
-- =======================
modifier.attacks = {
	shoot = {
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
}

-- =======================
-- State system
-- =======================
--- @param chaser mobj_t
--- @param stateName string
function modifier:setState(chaser, stateName)
    chaser._state = stateName
    self.attacks[stateName].init(chaser, chaser.tracer)
end

--- @param chaser mobj_t
function modifier:updateState(chaser)
	local state = self.attacks[chaser._state]
	if not state then return end

	state.update(chaser, chaser.tracer)
end

-- =======================
-- Basic AI config
-- =======================
modifier.chaseDelay = TICRATE

freeslot("MT_FH_REMILIA_CHASER", "S_FH_REMILIA_CHASER")
freeslot("MT_FH_BULLET")
freeslot("S_FH_REGULARBULLET", "S_FH_COOLERLOOKINGBULLET", "S_FH_BEAMBULLET", "S_FH_REMIBAT")

mobjinfo[MT_FH_BULLET].radius = 8 * FU
mobjinfo[MT_FH_BULLET].height = 16 * FU
mobjinfo[MT_FH_BULLET].flags = MF_NOGRAVITY | MF_MISSILE
mobjinfo[MT_FH_BULLET].spawnstate = S_FH_REGULARBULLET
mobjinfo[MT_FH_BULLET].speed = 8 * FU

states[S_FH_REGULARBULLET].sprite = freeslot("SPR_RBL2")
states[S_FH_REGULARBULLET].frame = FF_FULLBRIGHT
states[S_FH_REGULARBULLET].action = A_GhostMe
states[S_FH_REGULARBULLET].tics = -1

states[S_FH_COOLERLOOKINGBULLET].sprite = freeslot("SPR_RBL1")
states[S_FH_COOLERLOOKINGBULLET].frame = FF_FULLBRIGHT
states[S_FH_COOLERLOOKINGBULLET].action = A_GhostMe
states[S_FH_COOLERLOOKINGBULLET].tics = -1

states[S_FH_REMIBAT].sprite = freeslot("SPR_RBAT")
states[S_FH_REMIBAT].frame = FF_FULLBRIGHT|FF_ANIMATE
states[S_FH_REMIBAT].action = A_GhostMe
states[S_FH_REMIBAT].var1 = C
states[S_FH_REMIBAT].var2 = 3
states[S_FH_REMIBAT].tics = -1

states[S_FH_BEAMBULLET].sprite = freeslot("SPR_RBEM")
states[S_FH_BEAMBULLET].frame = FF_FULLBRIGHT
states[S_FH_BEAMBULLET].action = A_GhostMe

mobjinfo[MT_FH_REMILIA_CHASER].radius = 48 * FU
mobjinfo[MT_FH_REMILIA_CHASER].height = 64 * FU
mobjinfo[MT_FH_REMILIA_CHASER].flags = MF_NOCLIP | MF_NOCLIPHEIGHT | MF_NOGRAVITY | MF_SPECIAL
mobjinfo[MT_FH_REMILIA_CHASER].spawnstate = S_FH_REMILIA_CHASER

states[S_FH_REMILIA_CHASER].sprite = freeslot("SPR_REMI")
states[S_FH_REMILIA_CHASER].frame = A
states[S_FH_REMILIA_CHASER].tics = -1
states[S_FH_REMILIA_CHASER].nextstate = S_FH_REMILIA_CHASER

-- =======================
-- Closest player
-- =======================
local function getClosestPlayer(remiliaChaser)
    local target
    local dist

    for player in players.iterate do
        if not player.mo or not player.mo.health or not player.mo.valid then continue end
        if not player.hr or player.hr.escaped or player.hr.downed then continue end

        local playerDist = R_PointToDist2(
            0, remiliaChaser.z,
            R_PointToDist2(remiliaChaser.x, remiliaChaser.y, player.mo.x, player.mo.y),
            player.mo.z
        )

        if not target or playerDist < dist then
            target = player
            dist = playerDist
        end
    end

    return target, dist
end

-- =======================
-- Init, update, finish
-- =======================
function modifier:init()
    local gametype = FH:isMode()
    local x, y, z

    for mapthing in mapthings.iterate do
        if mapthing.type == gametype.signpostThing then
            x, y, z = FH:getMapthingWorldPosition(mapthing)
        end
    end

    P_SetupLevelSky(87)
    for player in players.iterate do
        P_SetSkyboxMobj(nil, player)
    end

    local remiliaChaser = P_SpawnMobj(x, y, z, MT_FH_REMILIA_CHASER)
    FHR.remiliaChaser = remiliaChaser
    FHR.remiliaChaserDelay = self.chaseDelay
end

function modifier:update()
    local remiliaChaser = FHR.remiliaChaser

    if not remiliaChaser or not remiliaChaser.valid then
        self:init()
        remiliaChaser = FHR.remiliaChaser
    end

    if FHR.remiliaChaserDelay then
        FHR.remiliaChaserDelay = FHR.remiliaChaserDelay - 1
    end
end

function modifier:finish()
    local remiliaChaser = FHR.remiliaChaser

    if remiliaChaser and remiliaChaser.valid then
        P_RemoveMobj(remiliaChaser)
    end
    FHR.remiliaChaser = nil
end

-- =======================
-- Bullet utility
-- =======================
--- @param chaser mobj_t
--- @param point vector3_t
--- @param speed fixed_t|nil
function modifier:bulletToPoint(chaser, point, speed)
    local m = P_SpawnMobjFromMobj(chaser, 0, 0, chaser.height / 2 - mobjinfo[MT_FH_BULLET].height / 2, MT_FH_BULLET)
    if not m or not m.valid then return end

	m.frame = ($ & ~FF_FRAMEMASK)|P_RandomRange(A, P)

    local sx, sy, sz = m.x, m.y, m.z + m.height / 2
    local dx, dy, dz = point.x - sx, point.y - sy, point.z - sz
    local mag = FH:pointTo3DDist(0,0,0, dx, dy, dz)
    if mag == 0 then return m end

    dx, dy, dz = FixedDiv(dx, mag), FixedDiv(dy, mag), FixedDiv(dz, mag)
    speed = speed or m.info.speed

    m.momx = FixedMul(speed, dx)
    m.momy = FixedMul(speed, dy)
    m.momz = FixedMul(speed, dz)

    return m
end

local function setTarget(chaser, target)
	chaser.tracer = target
	modifier:setState(chaser, "bigBulletShoot")
end

-- =======================
-- Mobj thinker hook
-- =======================
--- @param remiliaChaser mobj_t
addHook("MobjThinker", function(remiliaChaser)
	if not remiliaChaser.valid then return end

	remiliaChaser.shadowscale = FU

	if FHR.remiliaChaserDelay then
		return
	end

	-- =======================
	-- Target acquisition
	-- =======================
	if not (remiliaChaser.tracer
	and remiliaChaser.tracer.valid
	and remiliaChaser.tracer.health
	and remiliaChaser.tracer.player
	and remiliaChaser.tracer.player.hr
	and not remiliaChaser.tracer.player.hr.downed
	and not remiliaChaser.tracer.player.hr.escaped) then
		local target = getClosestPlayer(remiliaChaser)
		if target then
			setTarget(remiliaChaser, target.mo)
		else
			remiliaChaser.tracer = nil
		end
	end

	if remiliaChaser.tracer then
		local angle = R_PointToAngle2(remiliaChaser.x, remiliaChaser.y, remiliaChaser.tracer.x, remiliaChaser.tracer.y)
		local distXY = 128 * FU
		local flyZ = 64 * FU

		-- direction vector to player (center-to-center)
		local dx = (remiliaChaser.tracer.x + P_ReturnThrustX(nil, angle, -distXY)) - remiliaChaser.x
		local dy = (remiliaChaser.tracer.y + P_ReturnThrustY(nil, angle, -distXY)) - remiliaChaser.y
		local dz = ((remiliaChaser.tracer.z + remiliaChaser.tracer.height/2) + flyZ)
		         - (remiliaChaser.z + remiliaChaser.height/2)

		local dist = FH:pointTo3DDist(0, 0, 0, dx, dy, dz)
		if dist > 0 then
			-- normalize
			local ndx = FixedDiv(dx, dist)
			local ndy = FixedDiv(dy, dist)
			local ndz = FixedDiv(dz, dist)

			local maxSpeed = 24 * (dist > 0 and FixedDiv(dist, 128 * FU) or 0)
			local desiredMomX = FixedMul(ndx, maxSpeed)
			local desiredMomY = FixedMul(ndy, maxSpeed)
			local desiredMomZ = FixedMul(ndz, maxSpeed / 4)

			-- if mobj is moving backwards from tracer, divide momentum values
			local curDist = FH:pointTo3DDist(
				remiliaChaser.x,
				remiliaChaser.y,
				0, -- remiliaChaser.z + remiliaChaser.height / 2,
				remiliaChaser.tracer.x,
				remiliaChaser.tracer.y,
				0 -- remiliaChaser.tracer.z + remiliaChaser.height / 2
			)
			local futureDist = FH:pointTo3DDist(
				remiliaChaser.x + desiredMomX,
				remiliaChaser.y + desiredMomY,
				0, -- remiliaChaser.z + remiliaChaser.height / 2 + desiredMomZ,
				remiliaChaser.tracer.x,
				remiliaChaser.tracer.y,
				0 -- remiliaChaser.tracer.z + remiliaChaser.height / 2
			)

			if curDist < futureDist then
				local mul = FU / 7
				desiredMomX = FixedMul($, mul)
				desiredMomY = FixedMul($, mul)
				-- desiredMomZ = FixedMul($, mul)
			end

			remiliaChaser.momx = desiredMomX
			remiliaChaser.momy = desiredMomY
			remiliaChaser.momz = desiredMomZ
		end
	end

	local friction = FU * 10 / 11
	remiliaChaser.momx = FixedMul($, friction)
	remiliaChaser.momy = FixedMul($, friction)
	remiliaChaser.momz = FixedMul($, friction)

	-- =======================
	-- Attack / state logic
	-- =======================
	-- modifier:updateState(remiliaChaser)
end, MT_FH_REMILIA_CHASER)

addHook("TouchSpecial", function(remiliaChaser, victim)
	victim.momx = -$
	victim.momy = -$

	--- @type heistOverlay_t
	local overlay = P_SpawnMobjFromMobj(remiliaChaser, 0,0,0, MT_FH_OVERLAY)
	overlay.alphaFuse = 10
	overlay.translation = "FH_AllRed"
	overlay.target = remiliaChaser

	return true
end, MT_FH_REMILIA_CHASER)

return FH:registerModifier(modifier)