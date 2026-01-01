--- @type heistModifier_t
local modifier = setmetatable({}, FH:returnModifierMetatable())

modifier.name = "Air-borne"
modifier.description = "Stay off the ground! You have a limited time to stay on it until' you are downed. Refill it by killing enemies!"
modifier.type = "side"

modifier.groundedTime = 3 * 17

function modifier:init()
	for player in players.iterate do
		if not player.heistRound then continue end

		player.heistRound.groundedTime = self.groundedTime
	end
end

function modifier:playerUpdate(player)
	if not player.mo then return end
	if P_PlayerInPain(player) then return end
	if not player.mo.health then return end
	if player.heistRound.downed then return end
	if player.heistRound.escaped then return end

	if P_IsObjectOnGround(player.mo) then
		player.heistRound.groundedTime = $ - 1

		if player.heistRound.groundedTime == 0 then
			FH:downPlayer(player, 5 * TICRATE)
			player.heistRound.groundedTime = self.groundedTime
		end
	end
end

function modifier:finish()
	FHR.bombCooldown = nil
end

addHook("MobjDamage", function(target, _, source)
	if not FH:isMode() then return end
	if not FH:isModifierActive(modifier) then return end
	if not source then return end
	if not source.valid then return end
	if not source.type == MT_PLAYER then return end
	if not source.player then return end
	if not source.player.heistRound then return end

	source.player.heistRound.groundedTime = modifier.groundedTime
end)

return FH:registerModifier(modifier)