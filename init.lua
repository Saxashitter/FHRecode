G_AddGametype({
    name = "muh gamemode",
    identifier = "fangsheist",
    typeoflevel = TOL_COOP,
    rules = 0,
    intermissiontype = int_none,
    headercolor = 103,
    description = "Chill out from the battles and races and relax with your friends in your favorite levels without a care in the world."
})

rawset(_G, "FH", {})
rawset(_G, "FHN", {}) -- network synched
rawset(_G, "FHR", {}) -- network synched

dofile("config.lua")
dofile("game.lua")