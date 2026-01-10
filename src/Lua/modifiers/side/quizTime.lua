--- @type heistModifier_t
local modifier = setmetatable({}, FH:returnModifierMetatable())

modifier.name = "Quiz Time"
modifier.description = "The game will abruptly stopped, and you will be quizzed."
modifier.type = "side"

function modifier:init()
	FHR.quizTimeSwitch = P_RandomRange(5, 50 * TICRATE)
end

function modifier:update()
	if not FHR.ringDrainTics then
		FH:setGamestate("quiztime")
		FHR.ringDrainTics = P_RandomRange(5, 50 * TICRATE)
	end

	FHR.ringDrainTics = $ - 1
end

return FH:registerModifier(modifier)