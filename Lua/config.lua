--- config.lua
--- Main place for class definitions, freeslots, and the likes.

--- Global tables
rawset(_G, "FH", {
    --- @type heistGametype_t[]
    gametypes = {}
})
rawset(_G, "FHN", {}) -- network synched
rawset(_G, "FHR", {}) -- network synched