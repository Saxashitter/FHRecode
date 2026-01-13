--- General definition for gametypes.
--- @class heistGametype_t
--- Determines the internal ID used for checking the mode within the code.
--- @field id string
--- Determines the name shown to the players within the Scoreboard, Map Vote, etc.
--- @field name string
--- Determines the description shown in SRB2's Map Selection.
--- @field description string
--- Determines the type of level this mode looks for within the Map Vote and SRB2's Map Selection
--- @field typeoflevel number
--- Determines the gametype's rules, used within SRB2 internally.
--- @field rules number
--- Determines the color of the header for the mode.
--- @field headercolor number
--- If this is true, when the player is downed, they will die.
--- @field killOnDowned boolean
--- If true, there are teams in the gametype.
--- @field teams boolean
--- Runs upon gametype initalization, after Fang's Heist initalizes itself.
--- @field init fun(self: heistGametype_t, gamemap: number)
--- Runs during MapLoad, useful for initalizing points of objects within maps.
--- @field load fun(self: heistGametype_t)
--- Runs every tic that the game is active for.
--- @field update fun(self: heistGametype_t, currentState: string)
--- Runs every tic for every player, regardless if they are dead or alive. Follows the same rules as the update function.
--- @field playerUpdate fun(self: heistGametype_t, player: player_t, currentState: string)
--- Runs once player.hr is initalized. Useful for appending variables in certain modes.
--- @field playerInit fun(self: heistGametype_t, player: player_t, currentState: string)
--- Runs once the player quits.
--- @field playerQuit fun(self: heistGametype_t, player: player_t, currentState: string)
--- Runs once the player dies.
--- @field playerDeath fun(self: heistGametype_t, player: player_t, currentState: string)
--- Runs upon the game ending, useful for de-initing or stopping stuff.
--- @field finish fun(self: heistGametype_t, currentState: string)
--- HUD replacements, referenced by [ui.name]
--- @field hud table
--- Runs immediately after the finish function. Return a list of sorted players to determine their place on the leaderboard, or return nil to use the default profit-sorted list.
--- @field declareWinner fun(self: heistGametype_t, players: player_t[]): player_t[]|nil
--- Runs when a player collects profit.
--- @field addProfit fun(self: heistGametype_t, player: player_t, profit: fixed_t, tag: string)
--- Runs when the player gets hurt.
--- @field playerDamage fun(self: heistGametype_t, target: player_t, inflictor: mobj_t, source: mobj_t)
--- @field __index heistGametype_t

--- @type heistGametype_t
local heistGametype_t = {
	__index = nil, -- emmylua fucks this up so i have to put this here
	id = "example",
	name = "Example",
	description = "Hi! This is an example description.",
	typeoflevel = TOL_COOP,
	rules = 0,
	headercolor = 103,
	killOnDowned = false,
	teams = true,
	hud = {},

	init = function() end,
	load = function() end,
	update = function() end,
	playerInit = function() end,
	playerUpdate = function() end,
	playerQuit = function() end,
	playerDeath = function() end,
	finish = function() end,
	declareWinner = function() end,
	addProfit = function() end,
	playerDamage = function() end
}
heistGametype_t.__index = heistGametype_t

--- Return the gametype metatable for use with creating gametypes.
--- @return heistGametype_t
function FH:returnGametypeMetatable()
	return heistGametype_t
end

--- Add a gametype to Fang's Heist.
--- @param gametypeStruct heistGametype_t
--- @return heistGametype_t
function FH:addGametype(gametypeStruct)
	table.insert(self.gametypes, gametypeStruct)

	G_AddGametype{
		identifier = gametypeStruct.id,
		name = gametypeStruct.name,
		description = gametypeStruct.description,
		typeoflevel = gametypeStruct.typeoflevel,
		rules = gametypeStruct.rules,
		headercolor = gametypeStruct.headercolor,
		intermissiontype = int_none,
	}
	self.gametypeByID[_G["GT_"..gametypeStruct.id:upper()]] = #self.gametypes

	return gametypeStruct
end

--- Get a gametype that exists within Fang's Heist using the gametype's ID.
--- @param gametypeID string
--- @return heistGametype_t|false
function FH:getGametype(gametypeID)
	for k, v in ipairs(FH.gametypes) do
		if v.id == gametypeID then
			return v
		end
	end

	return false
end

--- Copy a gametype, useful for instancing from other modes instead of copying all of the code.
--- @param gametype heistGametype_t
--- @return table
function FH:copyGametype(gametype)
	local function copy(tbl)
		local new = {}
		for k, v in pairs(tbl) do
			if type(v) == "table" then
				new[k] = copy(v)
				continue
			end

			new[k] = v
		end
	end

	--- @type heistGametype_t
	local c = copy(gametype)
	c.hud = {} -- for safety

	return c
end

--- Call a function on the gametype key given.
--- @param gametypeKey number
--- @return any|nil
function FH:callGametypeFunc(gametypeKey, key, ...)
	--- @type heistGametype_t
	local gametype = FH.gametypes[gametypeKey]

	if gametype[key] then
		return gametype[key](gametype, ...)
	end
end

--- Returns heistGametype_t if the player is playing a Fang's Heist gamemode, otherwise false.
--- @return heistGametype_t|false
function FH:isMode()
	if self.gametypeByID[gametype] == nil then
		return false
	end

	--- @type heistGametype_t
	return FH.gametypes[self.gametypeByID[gametype]]
end


--- Get all gametypes within Fang's Heist
dofile("gametypes/escape/init.lua")
dofile("gametypes/battle/init.lua")