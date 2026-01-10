--- House-keeping for rounds, per-match.
--- @class heistRoundGlobal_t
--- Determines the current state of the game. It's recommended not to touch this, and instead use FH:setGamestate, but nobody's stopping you from modding it yourself.
--- @field currentState string

-- TODO: Allow modes to add their own states.
function FH:setGamestate(stateName, dontInitalize)
	if not self.gamestates[stateName] then return end

	local state = self.gamestates[stateName]

	if not dontInitalize then
		state:init()
	end
	FHR.currentState = stateName
end

--- Initalize the game round, ran inside MapChange.
--- @param gametype heistGametype_t
--- @param gamemap number
function FH:initRound(gametype, gamemap)
	--- @type heistRoundGlobal_t
	local roundGlobal = {
		currentState = "",
		modifiers = {}
	}
	FHR = roundGlobal

	for player in players.iterate do
		FH:initPlayerRound(player)
	end

	self:setGamestate("pregame")
	gametype:init(gamemap)
end

function FH:endGame()
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end

	self:setGamestate("intermission")
	gametype:finish(FHR.currentState)

	P_SwitchWeather(0)
end

function FH:getPlayerPlace(player)
	local place = 1
	local leader = player.heistGlobal.team.players[1]

	for other in players.iterate do
		if not FH:isTeamLeader(other) then continue end
		if other == leader then continue end
		if not other.heistRound then continue end
		if other.heistRound.spectator then continue end
		if other.heistRound.profit <= leader.heistRound.profit then continue end

		place = place + 1
	end

	return place
end

addHook("MapChange", function(gamemap)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end

	FH:initRound(gametype, gamemap)
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

addHook("MusicChange", function(old, new)
	if new == mapmusname and FHN.globalMusic then
		if old == FHN.globalMusic then
			return true
		end

		return FHN.globalMusic
	end
end)

addHook("GameQuit", function()
	FHR = {}

	FHN.retakes = 0 -- making sure
	FHN.lastMap = nil
	FHN.globalMusic = nil
end)

--- Get all gamestates within Fang's Heist.
dofile("gamestates/pregame.lua")
dofile("gamestates/titlecard.lua")
dofile("gamestates/game.lua")
dofile("gamestates/intermission.lua")
dofile("gamestates/mapvote.lua")
dofile("gamestates/rottenboy.lua")
dofile("gamestates/quiztime.lua")