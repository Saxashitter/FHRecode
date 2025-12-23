--- Global tables
rawset(_G, "FH", {
    --- @type heistGametype_t[]
    gametypes = {},
    gametypeByID = {}
})
rawset(_G, "FHN", {
    currentGametype = 1
}) -- network synched
rawset(_G, "FHR", {}) -- network synched
rawset(_G, "FHC", {})