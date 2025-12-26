local SKINS_ROW = 12
local SKINS_WIDTH = 16*FU
local SKINS_PADDING = 2*FU
local SKINS_UNSELECTED_SCALE = FU
local SKINS_SELECTED_SCALE = FU + FU / 4

local RIBBON_START_RADIUS = 5*FU
local RIBBON_END_RADIUS = 40*FU
local RIBBON_TWEEN = 7

local CHAR_TWEEN = 10

-- start x defined by text width
local TEXT_END_X = 8*FU
local TEXT_DELAY = 4
local TEXT_TWEEN = 12

--- @param player player_t
local function getTic(player)
	return leveltime - player.heistRound.selectedSkinTime
end

--- @param v videolib
--- @param player player_t
local function characterState(v, player)
	
end

--- @param v videolib
--- @param player player_t
return function(v, player)
	SSL.drawString(v, 160, 100, "Playing as: "..skins[player.skin].realname, "STCFN%03d", 0, FU/2, FU/2, nil, nil, 4*FU)
end