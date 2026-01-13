local battle = _FH_BATTLE
battle.hud = {} -- safety

local PATCHES = {
	["0"] = "STTNUM0",
	["1"] = "STTNUM1",
	["2"] = "STTNUM2",
	["3"] = "STTNUM3",
	["4"] = "STTNUM4",
	["5"] = "STTNUM5",
	["6"] = "STTNUM6",
	["7"] = "STTNUM7",
	["8"] = "STTNUM8",
	["9"] = "STTNUM9",
	["."] = "STTPERIO",
	[":"] = "STTCOLON",
}

local function drawRightAlignedNumber(v, x, y, text, flags)
	flags = flags or 0

	for i = #text, 1, -1 do
		local ch = text:sub(i, i)
		local patchName = PATCHES[ch]
		if patchName then
			local p = v.cachePatch(patchName)
			x = $ - 8
			v.draw(x, y, p, flags)
		end
	end
end


battle.hud["score"] = {}

--- @param v videolib
--- @param player player_t
function battle.hud.score:draw(v, player, camera, ui)
	--- @type tic_t
	local time = FHR.battleTime

	local timeString = ("%d:%02d.%02d"):format(G_TicsToMinutes(time), G_TicsToSeconds(time), G_TicsToCentiseconds(time))
	local timeX = 120

	local stt = v.cachePatch("STTTIME")

	v.draw(ui.x, ui.y, stt, ui.flags)
	drawRightAlignedNumber(v, timeX, ui.y, timeString, ui.flags)
end