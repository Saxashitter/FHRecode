local mapVoteMenu = {}

local mapScale = (FU / 10) * 4
local mapSpacing = 5 * FU

local borderSize = FU
local borderColorUnselected = 0
local borderColorSelected = 74
local borderColorConfirmed = 96

--- @param player player_t
function mapVoteMenu:draw(v, player)
	if FHR.currentState ~= "mapvote" then return end

	if not (player and player.valid) and (displayplayer and displayplayer.valid) then
		player = displayplayer
	elseif not (player and player.valid) then
		return
	end

	local screenWidth = v.width() * FU / v.dupx()
	local screenHeight = v.height() * FU / v.dupy()

	local tics = leveltime - FHR.mapVoteTime

	local background = v.cachePatch("FH_S2BACKGROUND")

	local backgroundStartX = -leveltime * FU / 3
	local backgroundStartY = -leveltime * FU / 3

	for y = backgroundStartY, screenHeight, background.height * FU do
		for x = backgroundStartX, screenWidth, background.width * FU do
			v.drawScaled(x, y, FU, background, V_SNAPTOLEFT|V_SNAPTOTOP)
		end
	end

	local maps = {}

	for _, map in ipairs(FHR.mapVoteMaps) do
		table.insert(maps, {
			patch = v.cachePatch(G_BuildMapName(map).."P"),
			name  = G_BuildMapTitle(map),
			votes = 0
		})
	end

	for otherPlayer in players.iterate do
		if not otherPlayer.hr then continue end
		if not otherPlayer.hr.mapVote then continue end

		maps[otherPlayer.hr.mapSelection].votes = $ + 1
	end

	if #maps == 0 then return end

	local totalWidth = 0
	for i, map in ipairs(maps) do
		totalWidth = $ + map.patch.width * mapScale
	
		if i < #maps then
			totalWidth = $ + mapSpacing
		end
	end

	local startX = (320 * FU - totalWidth) / 2

	local x = startX
	local y = 100 * FU - 100 * mapScale / 2

	for i, map in ipairs(maps) do
		local borderColor = borderColorUnselected
		local colorMap = 0

		if player and player.hr and player.hr.mapSelection == i then
			borderColor = borderColorSelected

			if player.hr.mapVote then
				borderColor = borderColorConfirmed
				colorMap = V_GREENMAP
			end

			SSL.drawFixedString(v, x + map.patch.width * mapScale / 2, y - borderSize - FU, FU, map.name, "TNYFN%03d", 0, FU / 2, FU, colorMap)
		end

		FH:drawPaletteRect(v, x - borderSize, y - borderSize, map.patch.width * mapScale + borderSize * 2, map.patch.height * mapScale + borderSize * 2, borderColor, 0)
		v.drawScaled(x, y, mapScale, map.patch, 0)
		SSL.drawFixedString(v, x + map.patch.width * mapScale / 2, y + map.patch.height * mapScale + borderSize + FU, FU, tostring(map.votes), "TNYFN%03d", 0, FU/2, 0, colorMap)

		x = $ + map.patch.width * mapScale + mapSpacing
	end

	if tics < 10 then
		FH:drawPaletteRect(v, 0, 0, screenWidth, screenHeight, 0, V_SNAPTOLEFT|V_SNAPTOTOP|(V_10TRANS * tics))
	end
end

return mapVoteMenu, "mapVoteMenu", 1, "menu"