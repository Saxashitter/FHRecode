--- Modifiable ring for different modes. You can make it have different actions depending on how the player jumps into it!

local MT_FH_RING = freeslot("MT_FH_RING")
local S_FH_GOALRING = freeslot("S_FH_GOALRING")
local SPR_GORI = freeslot("SPR_GORI")

FH.ringStates = {}

---@diagnostic disable-next-line: missing-fields
mobjinfo[MT_FH_RING] = {
	spawnstate = S_FH_GOALRING,
	radius = 25 * FU,
	height = 105 * FU,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SPECIAL,
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

--- Spawn a special ring, used mainly for escape modes.
--- @param x fixed_t
--- @param y fixed_t
--- @param z fixed_t
--- View mobjs/escape/specialring for different types of special rings. You can add one yourself as well while making a gamemode.
--- @param ringType string
--- @return mobj_t|false
function FH:spawnRing(x, y, z, ringType, ...)
	if not self.ringStates[ringType] then
		return false
	end

	local ringData = self.ringStates[ringType]
	print("Spawning ring type: "..ringType)

	local ring = P_SpawnMobj(x, y, z, MT_FH_RING)
	if not (ring and ring.valid) then
		return false
	end

	ring.ringState = ringData.state
	ring.ringType = ringType
	ringData.spawn(ring, ...)

	return ring
end

addHook("TouchSpecial", function(ring, player)
	if not player.valid then return true end

	local ringData = FH.ringStates[ring.ringType]
	ringData.touch(ring, player.player)

	return true
end, MT_FH_RING)