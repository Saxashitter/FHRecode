--- Global tables
rawset(_G, "FH", {
    gamestates = {},

    --- @type heistGametype_t[]
    gametypes = {},
    gametypeByID = {},

    uiElements = {
        game = {},
        scores = {},
        global = {}
    },
    uiEnabled = true

})
rawset(_G, "FHN", {
    currentGametype = 1
})
rawset(_G, "FHR", {})