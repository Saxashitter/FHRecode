--- Modifiable ring for different modes. You can make it have different actions depending on how the player jumps into it!

local MT_FH_RING = freeslot("MT_FH_RING")
local S_FH_GOALRING = freeslot("S_FH_GOALRING")
local SPR_GORI = freeslot("SPR_GORI")

FH.ringStates = {}

---@diagnostic disable-next-line: missing-fields
mobjinfo[MT_FH_RING] = {
	--$Title Special Ring
	--$Category Fang's Heist - Escape
	--$StringArg0 Ring Type (Goal|Round 2 Teleport From|Round 2 Teleport To)
	--$Sprite GORIA0
	doomednum = 4098,
	spawnstate = S_FH_GOALRING,
	radius = 35 * FU,
	height = 105 * FU,
	flags = MF_NOGRAVITY,
	raisestate = S_NULL
}

---@diagnostic disable-next-line: missing-fields
states[S_FH_GOALRING] = {
	sprite = SPR_GORI,
	frame = A|FF_ANIMATE,
	tics = -1,
	var1 = F,
	var2 = 2,
	nextstate = S_FH_GOALRING
}

--[[--- Spawn a special ring, used mainly for escape modes.
--- View mobjs/escape/specialring for different types of special rings. You can add one yourself as well while making a gamemode.
--- @param x fixed_t
--- @param y fixed_t
--- @param z fixed_t
--- @param ringType string
--- @return mobj_t|false
function FH:spawnRing(x, y, z, ringType, ...)
	if not self.ringStates[ringType] then
		return false
	end

	local ringData = self.ringStates[ringType]

	local ring = P_SpawnMobj(x, y, z, MT_FH_RING)
	if not (ring and ring.valid) then
		return false
	end

	ring.ringState = ringData.state
	ring.ringType = ringType
	ringData.spawn(ring, ...)

	return ring
end]]

addHook("MobjSpawn", function(ring)
	ring.ringState = S_FH_GOALRING
	ring.ringType = "Goal"
end, MT_FH_RING)

--- @param ring mobj_t
--- @param mapthing mapthing_t
addHook("MapThingSpawn", function(ring, mapthing)
	local ringType = mapthing.stringargs[0] or "Goal"
	local ringData = FH.ringStates[ringType]

	ring.ringState = ringData.state
	ring.ringType = ringType
	ring.state = ringData.state
	ringData.spawn(ring)
end, MT_FH_RING)


addHook("MobjCollide", function(ring, source)
	if not source then return end
	if not source.valid then return end
	if source.type ~= MT_PLAYER then return end
	if source.z > ring.z + ring.height then return end
	if ring.z > source.z + source.height then return end
	if not source.health then return end
	if not source.player then return end
	if P_PlayerInPain(source.player) then return end
	if not source.player.hr then return end
	if source.player.hr.downed then return end

	local ringData = FH.ringStates[ring.ringType]
	ringData.touch(ring, source.player)
end, MT_FH_RING)
addHook("MobjMoveCollide", function(ring, source)
	if not source then return end
	if not source.valid then return end
	if source.type ~= MT_PLAYER then return end
	if source.z > ring.z + ring.height then return end
	if ring.z > source.z + source.height then return end
	if not source.health then return end
	if not source.player then return end
	if P_PlayerInPain(source.player) then return end
	if not source.player.hr then return end
	if source.player.hr.downed then return end

	local ringData = FH.ringStates[ring.ringType]
	ringData.touch(ring, source.player)
end, MT_FH_RING)