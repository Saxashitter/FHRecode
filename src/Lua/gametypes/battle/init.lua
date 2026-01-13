--- Battle
--- It's a fight to the death!

local escape = setmetatable({}, FH:returnGametypeMetatable())
escape.id = "BATTLE"
escape.name = "Battle"
escape.description = "Work in progress."
escape.typeoflevel = freeslot("TOL_BATTLE")

escape.rules = GTR_SPAWNENEMIES|GTR_NOTITLECARD
escape.isBattle = true
escape.killOnDowned = true
escape.teams = false

rawset(_G, "_FH_BATTLE", escape)

dofile("gametypes/battle/game.lua")
dofile("gametypes/battle/player.lua")
dofile("gametypes/battle/hud.lua")

--- We're done! Delete the global and return.
rawset(_G, "_FH_BATTLE", nil)
return FH:addGametype(escape)