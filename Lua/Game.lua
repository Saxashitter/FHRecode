--- House-keeping for rounds, per-match.
--- @class heistRoundGlobal_t
--- Determines the current state of the game. It's recommended not to touch this, and instead use FH:setGamestate, but nobody's stopping you from modding it yourself.
--- @field currentState string

-- TODO: Allow modes to add their own states.
function FH:setGamestate(stateName)
	if not self.gamestates[stateName] then return end

	local state = self.gamestates[stateName]

	state:init()
	FHR.currentState = stateName
end

--- Initalize the game round, ran inside MapChange. This does not reset the gametype!
--- @param gametype heistGametype_t
function FH:initRound(gametype)
	--- @type heistRoundGlobal_t
	local roundGlobal = {
		currentState = "" -- set later
	}
	FHR = roundGlobal

	for player in players.iterate do
		FH:initPlayerRound(player)
	end

	FH:setGamestate("pregame")
	gametype:init()
end

function FH:endGame()
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end

	self:setGamestate("intermission")
	gametype:finish(FHR.currentState)
end

addHook("MapChange", function()
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end

	FH:initRound(gametype)
end)

addHook("MapLoad", function()
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end

	local state = FH.gamestates[FHR.currentState]

	state:load()
	gametype:load()
end)

addHook("ThinkFrame", function()
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end

	local state = FH.gamestates[FHR.currentState]

	state:update()
	gametype:update(FHR.currentState)
end)

--- @param network function
addHook("NetVars", function(network)
	FHN = network($)
	FHR = network($)
end)

--- Get all gamestates within Fang's Heist.
dofile("gamestates/pregame.lua")
dofile("gamestates/game.lua")
dofile("gamestates/intermission.lua")
dofile("gamestates/titlecard.lua")