--- House-keeping for rounds, per-match.
--- @class heistRoundGlobal_t

--- Returns heistGametype_t if the player is playing a Fang's Heist gamemode, otherwise false.
--- @return heistGametype_t|false
function FH:isMode()
	if self.gametypeByID[gametype] == nil then
		return false
	end

	--- @type heistGametype_t
	return FH.gametypes[self.gametypeByID[gametype]]
end

--- Initalize the game round, ran inside MapChange. This does not reset the gametype!
--- @param gametype heistGametype_t
function FH:initRound(gametype)
	--- @type heistRoundGlobal_t
	local roundGlobal = {}
	FHR = roundGlobal

	gametype:init()
end

addHook("MapChange", function()
	local gametype = FH:isMode()
	if not gametype then return end

	FH:initRound(gametype)
end)

addHook("ThinkFrame", function()
	--- @type heistGametype_t
	local gametype = FH.gametypes[FHN.currentGametype] or FH.gametypes[1]

	gametype:update()
end)

--- @param network function
addHook("NetVars", function(network)
	FHN = network($)
	FHR = network($)
end)