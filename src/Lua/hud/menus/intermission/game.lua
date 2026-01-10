local gameRiseTics = 35

local gameFallTics = 25
local gameFallDelay = 7

local gameShakeTics = 10
local gameShakeAmount = 6 * FU

local gameLetterRiseDelay = 12
local gameLetterRiseOffset = 7
local gameLetterRiseTics = 35

local gameScaleUpDelay = 2751 * TICRATE / MUSICRATE

local gameScaleDownTics = 15

local gameSmallScale = (FU / 4) * 3
local gameBigScale = FixedMul(gameSmallScale, FU * 3 / 2)

--- @param v videolib
return function(v)
	local state = FH.gamestates[FHR.currentState]
	local tics = leveltime - FHR.intermissionStartTime
	
	local afterBeat = tics >= state.gameScreenBeat
	local afterTics = max(0, tics - state.gameScreenBeat)

	local ending = afterTics >= 2 * TICRATE
	local endingTics = max(0, afterTics - 2 * TICRATE)

	local screenWidth = v.width() * FU / v.dupx()
	local screenHeight = v.height() * FU / v.dupy()

	-- local scaleUpTime = FixedDiv(min(max(tics - gameScaleUpDelay, 0), state.gameScreenBeat - gameScaleUpDelay), state.gameScreenBeat - gameScaleUpDelay)
	-- local scaleDownTime = FixedDiv(min(max(tics - state.gameScreenBeat, 0), gameScaleDownTics), gameScaleDownTics)
	-- local riseTime = FixedDiv(min(tics, gameRiseTics), gameRiseTics)
	-- local letterRiseTime = FixedDiv(min(max(tics - gameLetterRiseDelay, 0), gameLetterRiseTics), gameLetterRiseTics)

	local scaleUpTime = FH:easeTime(tics, state.gameScreenBeat - gameScaleUpDelay, gameScaleUpDelay)
	local scaleDownTime = FH:easeTime(tics, gameScaleDownTics, state.gameScreenBeat)
	local riseTime = FH:easeTime(tics, gameRiseTics)
	local fallTime = FH:easeTime(endingTics, gameFallTics, gameFallDelay)
	local shakeTime = FU - FH:easeTime(afterTics, gameShakeTics)

	local gameBG = v.cachePatch("FH_GAME6")
	local game = {}
	for i = 1, 5 do
		game[i] = v.cachePatch("FH_GAME"..i)
	end

	-- background for everything
	local gameBGScale = ease.inquad(scaleUpTime, gameSmallScale, gameBigScale)
	if afterBeat then
		local background = v.cachePatch("FH_S2BACKGROUND")

		local backgroundStartX = -leveltime * FU / 3
		local backgroundStartY = -leveltime * FU / 3

		local darkTrans = 10 - min(10, endingTics)

		if darkTrans > 0 then
			for y = backgroundStartY, screenHeight, background.height * FU do
				for x = backgroundStartX, screenWidth, background.width * FU do
					v.drawScaled(x, y, FU, background, V_SNAPTOLEFT|V_SNAPTOTOP)
				end
			end
			if afterTics < 10 then
				FH:drawPaletteRect(v, 0, 0, screenWidth, screenHeight, 0, V_SNAPTOLEFT|V_SNAPTOTOP|(V_10TRANS * afterTics))
			end
			if darkTrans < 10 then
				FH:drawPaletteRect(v, 0, 0, screenWidth, screenHeight, 31, V_SNAPTOLEFT|V_SNAPTOTOP|(V_10TRANS * darkTrans))
			end
		else
			v.drawFill()
		end

		gameBGScale = ease.outcubic(scaleDownTime, gameBigScale, gameSmallScale)
	end

	-- game background
	local gameBGX = 160 * FU - gameBG.width * gameBGScale / 2
	local gameBGY = ease.outcubic(riseTime, screenHeight, screenHeight / 2 - gameBG.height * gameBGScale / 2)

	if afterBeat then
		gameBGX = $ + FixedMul(v.RandomRange(-gameShakeAmount, gameShakeAmount), shakeTime)
		gameBGY = $ + FixedMul(v.RandomRange(-gameShakeAmount, gameShakeAmount), shakeTime)
	end
	if ending then
		gameBGY = ease.inquad(fallTime, $, screenHeight)
	end

	v.drawScaled(gameBGX, gameBGY, gameBGScale, gameBG, V_SNAPTOTOP)

	-- the entire game thing
	local gameScale = gameBGScale

	local gameWidth = 0
	local gameHeight = 0

	for k, v in ipairs(game) do
		gameWidth = $ + v.width * gameScale
		gameHeight = max(0, v.height * gameScale)
	end

	local gameX = 160 * FU - gameWidth / 2
	local gameY = gameBGY

	for i, game in ipairs(game) do
		local letterRiseTime = FH:easeTime(tics, gameLetterRiseTics, gameLetterRiseDelay + gameLetterRiseOffset * (i - 1))
		local letterX = gameX
		local letterY = ease.outback(
			letterRiseTime,
			screenHeight,
			(gameY + gameBG.height * gameBGScale / 2 - gameHeight / 2) + gameHeight - game.height * gameScale,
			2 * FU
		)

		if afterBeat then
			letterX = $ + FixedMul(v.RandomRange(-gameShakeAmount, gameShakeAmount), shakeTime)
			letterY = $ + FixedMul(v.RandomRange(-gameShakeAmount, gameShakeAmount), shakeTime)
		end

		v.drawScaled(letterX, letterY, gameScale, game, V_SNAPTOTOP)
		gameX = $ + game.width * gameScale
	end
end