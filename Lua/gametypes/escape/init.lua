--- Escape
--- Grab what you can and GO! GO! GO!
--- Base gamemode for all the other ones.

local escape = setmetatable({}, FH:returnGametypeMetatable())
rawset(_G, "_FH_ESCAPE", escape)

dofile("gametypes/escape/game.lua")

--- We're done! Delete the global and return.
rawset(_G, "_FH_ESCAPE", nil)
return FH:addGametype(escape)