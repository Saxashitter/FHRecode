local gamestate = {}

function gamestate:init()
end

function gamestate:update()
end

addHook("ShouldDamage", function(targ, inf, source)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end

	if FHR.currentState ~= "game" then return false end

	-- TODO: friendlyfire checks from the gamemode and the cvar
	if source and source.valid and source.type == MT_PLAYER then
		return true
	end
end, MT_PLAYER)

FH.gamestates.game = gamestate