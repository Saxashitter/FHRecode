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
			chaser.switchDelay = 2 * TICRATE
		end,

		--- @param chaser mobj_t
		--- @param target mobj_t
		update = function(chaser, target)
			-- bullet prediction code
			-- plan for attack:
				-- bullets can be weaved easily by moving to the side, moving directly forward = hurt
				-- 1 second delay until next attack is done (random)

			if chaser.shotDelay then
				chaser.shotDelay = $ - 1
				return
			end
			chaser.shotDelay = 3

			for i = 1, 2 do
				local random = 128 * FU
				local randomZ = 32 * FU
				local momMult = FU * 15

				local angle = R_PointToAngle2(chaser.x, chaser.y, target.x, target.y)
				local randomXY = FH:fixedRandom(-240 * FU, 240 * FU)

				local bullet = modifier:bulletToPoint(chaser, {
					x = target.x + FixedMul(randomXY, cos(angle - ANGLE_90)) + FixedMul(target.momx, momMult),
					y = target.y + FixedMul(randomXY, sin(angle - ANGLE_90)) + FixedMul(target.momy, momMult),
					z = target.z + target.height / 2 + FH:fixedRandom(-randomZ, randomZ) + FixedMul(target.momz, momMult)
				}, mobjinfo[MT_FH_BULLET].speed + FixedMul(FH:pointTo3DDist(0,0,0, target.momx, target.momy, target.momz), (FU * 6) / 10))

				if bullet and bullet.valid then
					bullet.momx = $ + FixedMul(randomXY, cos(angle - ANGLE_90)) / 100
					bullet.momy = $ + FixedMul(randomXY, sin(angle - ANGLE_90)) / 100
				end
			end
		end
    }
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
mobjinfo[MT_FH_BULLET].speed = 20 * FU

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
mobjinfo[MT_FH_REMILIA_CHASER].flags = MF_NOCLIP | MF_NOCLIPHEIGHT | MF_NOGRAVITY | MF_NOBLOCKMAP
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
	modifier:setState(chaser, "shoot")
end

-- =======================
-- Mobj thinker hook
-- =======================
addHook("MobjThinker", function(remiliaChaser)
    if not remiliaChaser.valid then return end

	if FHR.remiliaChaserDelay then
		return
	end

	if not (remiliaChaser.tracer
	and remiliaChaser.tracer.valid
	and remiliaChaser.tracer.health
	and remiliaChaser.tracer.player
	and remiliaChaser.tracer.player.hr
	and not remiliaChaser.tracer.player.hr.downed
	and not remiliaChaser.tracer.player.hr.escaped) then
		local target, _ = getClosestPlayer(remiliaChaser)
		if target then
			setTarget(remiliaChaser, target.mo)
		else
			remiliaChaser.tracer = nil
		end
	end

	if not remiliaChaser.tracer then
		remiliaChaser._state = nil
	else
		local angle = R_PointToAngle2(remiliaChaser.x, remiliaChaser.y, remiliaChaser.tracer.x, remiliaChaser.tracer.y)

		local nx = remiliaChaser.tracer.x + P_ReturnThrustX(nil, angle, -128 * FU)
		local ny = remiliaChaser.tracer.y + P_ReturnThrustY(nil, angle, -128 * FU)
		local nz = remiliaChaser.tracer.z + 64 * FU

		if P_MobjFlip(remiliaChaser.tracer) < 0 then
			nz = remiliaChaser.tracer.z - 64 * FU
			remiliaChaser.eflags = $|MFE_VERTICALFLIP
		end

		local cx = ease.linear(FU / 6, remiliaChaser.x, nx)
		local cy = ease.linear(FU / 6, remiliaChaser.y, ny)
		local cz = ease.linear(FU / 9, remiliaChaser.z, nz)

		P_MoveOrigin(remiliaChaser, cx, cy, cz)
	end

	modifier:updateState(remiliaChaser)
end, MT_FH_REMILIA_CHASER)

return FH:registerModifier(modifier)