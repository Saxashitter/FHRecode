--- @type heistModifier_t
local modifier = setmetatable({}, FH:returnModifierMetatable())

modifier.name = "Bombs"
modifier.description = "You want it? It's your's my friend! As long as you have enough rupees!"
modifier.type = "side"

modifier.spawnDelay = TICRATE
modifier.spawnHeight = 250 * FU

--- @param player player_t
function modifier:predictPlayerPosition(player)
    local mo = player.mo
    local info = mobjinfo[MT_FBOMB]

    local x = 0
	local y = 0
	local z = mo.z + self.spawnHeight

	if mo.ceilingz - info.height <= z then
		z = mo.ceilingz - info.height
	end

	local playerDistance = abs(z - mo.z)
	local gravity = abs(P_GetMobjGravity(player.mo))

	if gravity == 0 or playerDistance == 0 then
		return x, y, z - mo.z -- bail early to prevent divide error
	end

	local ticsUntilHit = FixedSqrt(FixedDiv(2 * playerDistance, gravity)) or 0

	x = FixedMul(mo.momx, ticsUntilHit)
	y = FixedMul(mo.momy, ticsUntilHit)

	return x, y, z - mo.z
end

function modifier:init()
	FHR.bombCooldown = self.spawnDelay
end

function modifier:update()
	FHR.bombCooldown = $ - 1

	if FHR.bombCooldown then return end
	FHR.bombCooldown = self.spawnDelay

	-- spawn bombs on top of all players

	for player in players.iterate do
		if not player.mo then return end
		if not player.mo.health then return end
		if player.heistRound.spectator then return end

		local predictx, predicty, predictz = self:predictPlayerPosition(player)
		if predictx == false then continue end

		P_SpawnMobjFromMobj(player.mo, predictx, predicty, predictz, MT_FBOMB)
	end
end

function modifier:finish()
	FHR.bombCooldown = nil
end

return FH:registerModifier(modifier)