--- @type heistModifier_t
local modifier = setmetatable({}, FH:returnModifierMetatable())

modifier.name = "Eggman"
modifier.description = "He's had enough of you!"
modifier.difficulty = "main"

modifier.chaseDelay = 3 * TICRATE

-- yknow, we are probably better off making this a mobj
-- but for testing sake, lets just keep it going :P
-- TODO: convert eggman chaser to mobj

freeslot("MT_FH_EGGMAN_CHASER", "S_FH_EGGMAN_CHASER", "MT_FH_ALERT")

mobjinfo[MT_FH_EGGMAN_CHASER].radius = 48 * FU
mobjinfo[MT_FH_EGGMAN_CHASER].height = 64 * FU
mobjinfo[MT_FH_EGGMAN_CHASER].flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SPECIAL
mobjinfo[MT_FH_EGGMAN_CHASER].spawnstate = S_FH_EGGMAN_CHASER

mobjinfo[MT_FH_ALERT].radius = FU
mobjinfo[MT_FH_ALERT].height = FU
mobjinfo[MT_FH_ALERT].flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOBLOCKMAP
mobjinfo[MT_FH_ALERT].spawnstate = S_ALART1

states[S_FH_EGGMAN_CHASER].sprite = SPR_EGGM
states[S_FH_EGGMAN_CHASER].frame = A
states[S_FH_EGGMAN_CHASER].tics = -1
states[S_FH_EGGMAN_CHASER].nextstate = S_FH_EGGMAN_CHASER

local function getClosestPlayer(eggmanChaser)
	local target
	local dist

	for player in players.iterate do
		if not player.mo then continue end
		if not player.mo.health then continue end
		if not player.mo.valid then continue end
		if not player.heistRound then continue end
		if player.heistRound.escaped then continue end
		if player.heistRound.downed then continue end

        -- Calculate the full 3D distance
        local playerDist = R_PointToDist2(0, eggmanChaser.z, R_PointToDist2(eggmanChaser.x, eggmanChaser.y, player.mo.x, player.mo.y), player.mo.z)

		if target == nil
		or playerDist < dist then
			target = player
			dist = playerDist
		end
	end

	return target, dist
end

function modifier:init()
	local gametype = FH:isMode()
	local x, y, z, angle
	
	for mapthing in mapthings.iterate do
		---@diagnostic disable-next-line: undefined-field
		if mapthing.type == gametype.signpostThing then
			x, y, z, angle = FH:getMapthingWorldPosition(mapthing)
		end
	end

	local eggmanChaser = P_SpawnMobj(x, y, z, MT_FH_EGGMAN_CHASER)
	FHR.eggmanChaser = eggmanChaser
	FHR.eggmanChaseDelay = self.chaseDelay
end

function modifier:update()
	local eggmanChaser = FHR.eggmanChaser

	if not eggmanChaser
	or not eggmanChaser.valid then
		self:init()
		eggmanChaser = FHR.eggmanChaser
	end

	if FHR.eggmanChaseDelay then
		FHR.eggmanChaseDelay = $ - 1
	end
end

function modifier:finish()
	local eggmanChaser = FHR.eggmanChaser

	if eggmanChaser and eggmanChaser.valid then
		P_RemoveMobj(eggmanChaser)
	end
	FHR.eggmanChaser = nil
end

-- mobj time
addHook("MobjThinker", function(eggmanChaser)
    local target, _ = getClosestPlayer(eggmanChaser)

    if target and not FHR.eggmanChaseDelay then
        local dist   = R_PointToDist2(eggmanChaser.x, eggmanChaser.y, target.mo.x, target.mo.y)
        local angle  = R_PointToAngle2(eggmanChaser.x, eggmanChaser.y, target.mo.x, target.mo.y)
        local aiming = R_PointToAngle2(0, 0, dist, target.mo.z - eggmanChaser.z)

       -- Vector toward player
		local dx = target.mo.x - eggmanChaser.x
		local dy = target.mo.y - eggmanChaser.y
		local dz = target.mo.z + target.mo.height/2 - (eggmanChaser.z + eggmanChaser.height/2)

		-- Distance to player
		local dist = R_PointToDist2(eggmanChaser.x, eggmanChaser.y, target.mo.x, target.mo.y)

		-- Rubberband factor
		local baseSpeed = 24 * FU
		local rubberband = max(1 * FU, dist / 500)
		local targetSpeed = FixedMul(baseSpeed, rubberband)

		-- Normalize vector
		local totalDist = dist + abs(dz)
		local vx = FixedDiv(dx, totalDist)
		local vy = FixedDiv(dy, totalDist)
		local vz = FixedDiv(dz, totalDist)

		local damp = FU / 6
	
		if eggmanChaser.tracer ~= target.mo then
			-- warn the player
			local alert = P_SpawnMobjFromMobj(target.mo, 0,0,0, MT_FH_ALERT)
			alert.target = target.mo
			alert.fuse = states[S_FANG_INTRO12].tics+10

			S_StartSound(target.mo, sfx_alart)
		end

		-- Set momentum proportional to targetSpeed
		eggmanChaser.momx = $ + FixedMul(damp, FixedMul(vx, targetSpeed))
		eggmanChaser.momy = $ + FixedMul(damp, FixedMul(vy, targetSpeed))
		eggmanChaser.momz = $ + FixedMul(damp, FixedMul(vz, targetSpeed))

        eggmanChaser.angle = angle
        eggmanChaser.tracer = target.mo
    else
        eggmanChaser.tracer = nil
    end

    -- Apply gentle friction for smooth stopping
    local friction = (FU / 25) * 23
    eggmanChaser.momx = FixedMul(eggmanChaser.momx, friction)
    eggmanChaser.momy = FixedMul(eggmanChaser.momy, friction)
    eggmanChaser.momz = FixedMul(eggmanChaser.momz, friction)
end, MT_FH_EGGMAN_CHASER)



addHook("TouchSpecial", function(eggmanChaser, player)
	if not player.health then return true end
	if not player.player then return true end
	if not player.player.heistRound then return true end
	if P_PlayerInPain(player.player) then return true end

	if not P_DamageMobj(player, eggmanChaser, eggmanChaser) then
		return true
	end

	eggmanChaser.momx = -$
	eggmanChaser.momy = -$
	eggmanChaser.momz = -$

	if player.fh_block then
		eggmanChaser.momx = $ * 5
		eggmanChaser.momy = $ * 5
		eggmanChaser.momz = $ * 5
	end

	return true
end, MT_FH_EGGMAN_CHASER)

addHook("MobjThinker", function(mobj)
	if not mobj.valid then return end
	if not mobj.target then return end
	if not mobj.target.valid then return end

	A_FH_Follow(mobj, 0, mobj.target.height / 2 + 4 * mobj.target.scale)
end, MT_FH_ALERT)

return FH:registerModifier(modifier)