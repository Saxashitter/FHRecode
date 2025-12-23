--- Escape
--- Grab what you can and GO! GO! GO!
--- Base gamemode for all the other ones.

--- Make global, then turn to local after we are done with initalization.
rawset(_G, "_FH_ESCAPE", {})
local escape = _FH_ESCAPE

--- We're done! Delete the global and return.
rawset(_G, "_FH_ESCAPE", nil)
return FH:addGametype(escape)