local gameRiseTics = 35

local gameLetterRiseDelay = 12
local gameLetterRiseTics = 35

local gameScaleUpDelay = 50

local gameScaleDownTics = 35

local gameScale = (FU / 4) * 3
local gameBigScale = FixedMul(gameScale, FU * 3 / 2)

return function(v)
	local state = FH.gamestates[FHR.currentState]
	local tics = leveltime - FHR.intermissionStartTime

	local screenWidth = v.width() * FU / v.dupx()
	local screenHeight = v.height() * FU / v.dupy()

	local scaleUpTime = FixedDiv(min(max(tics - gameScaleUpDelay, 0), state.gameScreenBeat - gameScaleUpDelay), state.gameScreenBeat - gameScaleUpDelay)
	local scaleDownTime = FixedDiv(min(max(tics - state.gameScreenBeat, 0), gameScaleDownTics), gameScaleDownTics)
	local riseTime = FixedDiv(min(tics, gameRiseTics), gameRiseTics)
	local letterRiseTime = FixedDiv(min(max(tics - gameLetterRiseDelay, 0), gameLetterRiseTics), gameLetterRiseTics)

	local gameBG = v.cachePatch("FH_GAME6")

	local scale = ease.inquad(scaleUpTime, gameScale, gameBigScale)
	if tics >= state.gameScreenBeat then
		local afterTics = tics - state.gameScreenBeat

		FH:drawPaletteRect(v, 0, 0, screenWidth, screenHeight, 31, V_SNAPTOLEFT|V_SNAPTOTOP)
		if afterTics < 10 then
			FH:drawPaletteRect(v, 0, 0, screenWidth, screenHeight, 0, V_SNAPTOLEFT|V_SNAPTOTOP|(V_10TRANS * afterTics))
		end

		scale = ease.outcubic(scaleDownTime, gameBigScale, gameScale)
	end

	local x = 160 * FU - gameBG.width * scale / 2
	local y = ease.outcubic(riseTime, screenHeight, screenHeight / 2 - gameBG.height * scale / 2)

	v.drawScaled(x, y, scale, gameBG, V_SNAPTOTOP)
end