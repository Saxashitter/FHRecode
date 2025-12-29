--- Global tables
rawset(_G, "FH", {
    gamestates = {},
    collectibles = {},

    --- @type heistGametype_t[]
    gametypes = {},
    gametypeByID = {},

    uiElements = {
        game = {},
        scores = {},
        global = {}
    },
    uiEnabled = true,

    characterHealths = {}
})
rawset(_G, "FHN", {
    currentGametype = 1
})
rawset(_G, "FHR", {})