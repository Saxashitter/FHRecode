local escape = _FH_ESCAPE

escape.timeLeft = 10 * TICRATE -- 2 minutes

function escape:init()
	FHN.escape = false
	FHN.escapeTime = 0
	print("Started.")
end

function escape:update()
	if FHN.escape then
		FHN.escapeTime = $ - 1
		if FHN.escapeTime % TICRATE == 0 then
			print("Tick... "..FHN.escapeTime / TICRATE)
		end

		if FHN.escapeTime == 0 then
			print("Disabled escape.")
			FHN.escape = false
		end
	end
end

--- @param player player_t
function escape:playerUpdate(player)
	if not player.mo then return end
	if not player.mo.health then return end

	print(FH:isPlayerInExitSector(player))

	if FH:isPlayerInExitSector(player) and not FHN.escape then
		escape:startEscape(player)
	end
end

--- Starts the escape sequence.
--- @param starter player_t
function escape:startEscape(starter)
	FHN.escape = true
	FHN.escapeTime = escape.timeLeft -- TODO: use cvars
	print("GO! GO! GO!")
end