--- Global tables
rawset(_G, "FH", {
    gamestates = {},
    collectibles = {},

    --- @type heistGametype_t[]
    gametypes = {},
    gametypeByID = {},

	modifiers = {
		types = {
            main = {},
            side = {}
        },
		all = {}
	},

    uiElements = {
        game = {},
        scores = {},
        global = {}
    },
    uiEnabled = true,

    characterHealths = {}
})
rawset(_G, "FHN", {})
rawset(_G, "FHR", {})