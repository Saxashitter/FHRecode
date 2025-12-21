G_AddGametype({
    name = "muh gamemode",
    identifier = "fangsheist",
    typeoflevel = TOL_COOP,
    rules = 0,
    intermissiontype = int_none,
    headercolor = 103,
    description = "Chill out from the battles and races and relax with your friends in your favorite levels without a care in the world."
})

--- @class FH
--- @field playerInit fun(player: player_t)

--- @type FH
rawset(_G, "FH", {})

--- @class FHN

--- @type FH
rawset(_G, "FHN", {})

dofile("Game.lua")