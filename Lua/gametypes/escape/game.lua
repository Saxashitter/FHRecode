local escape = _FH_ESCAPE

escape.timeLeft = 20 * TICRATE -- 2 minutes

function escape:init()
	FHN.escape = false
	FHN.escapeTime = 0
	print("Started.")
end

function escape:escapeUpdate()
	if FHN.escapeTime then
		FHN.escapeTime = $ - 1

		if FHN.escapeTime % TICRATE == 0 then
			print("Tick... "..FHN.escapeTime / TICRATE)
		end
	end
end

--- @param currentState string
function escape:update(currentState)
	if currentState ~= "game" then return end

	if FHN.escape then
		self:escapeUpdate()
	end
end

--- Starts the escape sequence.
--- @param starter player_t
function escape:startEscape(starter)
	FHN.escape = true
	FHN.escapeTime = escape.timeLeft -- TODO: use cvars
	FH:changeMusic("FH_ESC")
end