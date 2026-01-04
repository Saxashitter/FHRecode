--- Changes the song used for the mod. Unlike S_ChangeMusic, this globally changes it, even for new players.
--- Set this to nil to revert to the map's default music.
--- @param music string|nil
function FH:changeMusic(music, loop)
	if loop == nil then loop = true end
	if music == nil then
		FHN.globalMusic = nil
		S_ChangeMusic(mapheaderinfo[gamemap].musname, loop)
		return
	end

	FHN.globalMusic = music
	S_ChangeMusic(music, loop)
end

--- If this returns true, the table contains whatever your function tries to check for, along with the key and value.
--- @param tbl table
--- @param func fun(value: any): boolean
--- @return boolean
--- @return number
--- @return any|nil
function FH:doesTableHave(tbl, func)
	for k, v in ipairs(tbl) do
		if func(v) then
			return true, k, v
		end
	end

	return false, 0, nil
end