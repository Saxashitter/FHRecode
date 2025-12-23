--- House-keeping for rounds, per-match.
--- @class heistRoundGlobal_t

--- Initalize the game round, ran inside MapChange. This does not reset the gametype!
--- @param gametype heistGametype_t
function FH:initRound(gametype)
	--- @type heistRoundGlobal_t
	local roundGlobal = {}
	FHR = roundGlobal

	gametype:init()
end

addHook("MapChange", function()
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end

	FH:initRound(gametype)
end)

addHook("ThinkFrame", function()
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end

	gametype:update()
end)

--- @param network function
addHook("NetVars", function(network)
	FHN = network($)
	FHR = network($)
end)