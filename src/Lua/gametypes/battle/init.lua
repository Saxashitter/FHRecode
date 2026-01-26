--- Battle
--- It's a fight to the death!

local battle = setmetatable({}, FH:returnGametypeMetatable())
battle.id = "BATTLE"
battle.name = "Battle"
battle.description = "Work in progress."
battle.typeoflevel = freeslot("TOL_BATTLE")

battle.rules = GTR_SPAWNENEMIES|GTR_NOTITLECARD
battle.isBattle = true
battle.killOnDowned = true
battle.damageAwardsPlayers = false
battle.teams = false

rawset(_G, "_FH_BATTLE", battle)

dofile("gametypes/battle/game.lua")
dofile("gametypes/battle/player.lua")
dofile("gametypes/battle/hud.lua")

--- We're done! Delete the global and return.
rawset(_G, "_FH_BATTLE", nil)
return FH:addGametype(battle)