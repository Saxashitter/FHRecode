FH.currentSongPosition = 0

-- TODO: change music depending on who your spectating

--- Changes the song used. Unlike S_ChangeMusic, this globally changes it, even for new players. This should not be ran client-side.
--- Set this to nil to revert to the map's default music.
--- @param music string|nil
--- @param loop boolean|nil
function FH:changeMusic(music, loop)
	FH.currentSongPosition = 0

	for player in players.iterate do
		if not player.hr then return end

		player.hr.music = nil
	end

	if loop == nil then loop = true end
	if music == nil then
		FHN.globalMusic = nil
		FHN.globalMusicLoop = nil

		S_ChangeMusic(mapheaderinfo[gamemap].musname, loop)
		return
	end

	FHN.globalMusic = music
	FHN.globalMusicLoop = loop
	S_ChangeMusic(music, loop)
end

function FH:changePlayerMusic(player, music, loop)
	if not player then return end
	if not music then return end

	if loop == nil then loop = true end

	player.hr.music = music
	player.hr.musicLoop = loop

	if player == consoleplayer then
		FH.currentSongPosition = 0
		S_ChangeMusic(music, loop)
	end
end

local function getCurrentSong()
	local player = consoleplayer

	if player
	and player.valid
	and player.hr
	and player.hr.music then
		return player.hr.music, player.hr.musicLoop
	end

	return FHN.globalMusic, FHN.globalMusicLoop
end

addHook("MusicChange", function(old, new)
	if not FH:isMode() then return end

	local currentMusic, looped = getCurrentSong()

	if new == mapmusname and currentMusic then
		if old == currentMusic then
			return true, 0, looped, FH.currentSongPosition, 0, 0
		end

		return currentMusic, 0, looped, FH.currentSongPosition, 0, 0
	end
end)

addHook("ThinkFrame", function()
	if not FH:isMode() then return end

	local currentMusic, looped = getCurrentSong()

	if not currentMusic then return end

	if S_MusicName() ~= currentMusic then
		S_ChangeMusic(currentMusic, looped)
		S_SetMusicPosition(FH.currentSongPosition)
	end

	FH.currentSongPosition = S_GetMusicPosition()
end)

addHook("PlayerJoin", function(num)
	if not FH:isMode() then return end

	local currentMusic, looped = getCurrentSong()

	if not currentMusic then return end 
	if S_MusicName() == currentMusic then return end

	if consoleplayer and #consoleplayer == num then
		S_ChangeMusic(currentMusic, looped)
	end
end)