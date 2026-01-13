--- Escape
--- Grab what you can and GO! GO! GO!
--- Base gamemode for all the other ones.

local escape = setmetatable({}, FH:returnGametypeMetatable())
escape.id = "ESCAPE"
escape.name = "Escape"
escape.description = "Work in progress."
escape.typeoflevel = freeslot("TOL_ESCAPE")

escape.rules = GTR_SPAWNENEMIES|GTR_NOTITLECARD
escape.isEscape = true

rawset(_G, "_FH_ESCAPE", escape)

dofile("gametypes/escape/game.lua")
dofile("gametypes/escape/player.lua")

--- We're done! Delete the global and return.
rawset(_G, "_FH_ESCAPE", nil)
return FH:addGametype(escape)