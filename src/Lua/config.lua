--- Global tables
rawset(_G, "FH", {
    gamestates = {},
    collectibles = {},

	altSkins = {},

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
rawset(_G, "FHN", {
	retakes = 0
})
rawset(_G, "FHR", {})