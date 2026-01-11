--- @type heistModifier_t
local modifier = setmetatable({}, FH:returnModifierMetatable())

modifier.name = "Ring Drain"
modifier.description = "Don't let your ring count go to zero! If it does, you'll get downed!"
modifier.type = "side"

function modifier:init()
	FHR.ringDrainTics = TICRATE

	for player in players.iterate do
		if not player.mo then continue end
		if not player.mo.health then continue end
		if player.hr.spectator then continue end

		player.rings = max($, 50)
	end
end

function modifier:update()
	if not FHR.ringDrainTics then
		FHR.ringDrainTics = TICRATE
	end

	FHR.ringDrainTics = $ - 1
end

--- @param player player_t
function modifier:playerUpdate(player)
	if player.hr.downed then return end
	if not player.mo then return end
	if not player.mo.health then return end
	if player.hr.spectator then return end

	if not FHR.ringDrainTics then
		player.rings = $ - 1
	end

	if not player.rings then
		FH:setHealth(player, 0)

		player.rings = 50
	end
end

return FH:registerModifier(modifier)