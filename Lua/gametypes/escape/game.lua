local escape = _FH_ESCAPE

escape.timeLeft = 120 * TICRATE -- 2 minutes

function escape:init()
	FHN.escape = false
	FHN.escapeTime = 0
	print("Started.")
end

function escape:update()
	if FHN.escape then
		FHN.escapeTime = $ - 1

		if FHN.escapeTime == 0 then
			print("Disabled escape.")
			FHN.escape = false
		end
	end
end

--- Starts the escape sequence.
--- @param starter player_t
function escape:startEscape(starter)
	FHN.escape = true
	FHN.escapeTime = escape.timeLeft -- TODO: use cvars
	print("GO! GO! GO!")
end