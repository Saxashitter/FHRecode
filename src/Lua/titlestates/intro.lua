local state = {}

function state:load()
	self.logoTween = 0
	self.logoMaxTween = 29
	self.logoTicker = 5
	self.logoPhase = 0
	self.whiteFade = 10

	S_StopMusic()
end

function state:tick(v)
	if self.logoTicker then
		self.logoTicker = $ - 1
	elseif self.logoTween < self.logoMaxTween then
		self.logoTween = $ + 1
	end

	if self.whiteFade < 10 then
		self.whiteFade = $ + 1
	end

	if self.logoPhase == 0 and self.logoTicker == 0 and self.logoTween == 0 then
		S_StartSound(nil, sfx_s3k51)
	end

	if self.logoPhase == 0 and self.logoTween == self.logoMaxTween then
		self:slam()
	end

	if self.logoPhase == 1 and self.logoTween == self.logoMaxTween then
		self.logoPhase = 2
		S_StartSound(nil, sfx_s3k4a)
	end

	if self.logoPhase == 3 and self.logoTween == self.logoMaxTween then
		FH:changeTitlescreenState("mainmenu")
	end
end

function state:draw(v)
	local tween = FixedDiv(self.logoTween, self.logoMaxTween)
	local y

	local sw = v.width() * FU / v.dupx()
	local sh = v.height() * FU / v.dupy()

	local logo = v.cachePatch("FH_LOGO")
	local logoWidth = logo.width * FU
	local logoHeight = logo.height * FU

	local x = 160 * FU - logoWidth / 2

	if self.logoPhase == 0 then
		y = ease.inquad(tween, -logoHeight, (sh / 2) - (logoHeight / 2))
	elseif self.logoPhase == 1 then
		local fakeTween = tween * 2
		local targetY = (sh / 2) - (logoHeight / 2)
		local bounce = 50*FU

		if tween < FU / 2 then
			y = ease.outquad(fakeTween, targetY, targetY - bounce)
		else
			y = ease.inquad(fakeTween - FU, targetY - bounce, targetY)
		end
	elseif self.logoPhase == 2 then
		y = (sh / 2) - (logoHeight / 2)
	elseif self.logoPhase == 3 then
		y = ease.inquad(tween, (sh / 2) - (logoHeight / 2), sh)
	end

	if self.logoPhase >= 1 then
		local background = v.cachePatch("FH_S2BACKGROUND")

		local tileW = background.width * FU
		local tileH = background.height * FU
		
		local offsetX = (-leveltime * FU / 3) % tileW
		local offsetY = (-leveltime * FU / 3) % tileH

		for y = offsetY, sh, tileH do
			for x = offsetX, sw, tileW do
				v.drawScaled(x, y, FU, background, V_SNAPTOLEFT|V_SNAPTOTOP)
			end
		end
	end

	if self.whiteFade < 10 then
		FH:drawPaletteRect(v, 0, 0, sw, sh, 0, V_SNAPTOLEFT|V_SNAPTOTOP|(self.whiteFade * V_10TRANS))
	end

	if self.logoPhase == 1 and self.logoTicker then
		x = $ + v.RandomRange(-4 * FU, 4 * FU)
		y = $ + v.RandomRange(-4 * FU, 4 * FU)
	end

	v.drawScaled(x, y, FU, logo, V_SNAPTOTOP)
end

function state:pressed(keyName)
	if self.logoPhase == 0 then
		self:slam()
		return
	end

	if self.logoPhase == 3 then
		FH:changeTitlescreenState("mainmenu")
		return
	end

	self:confirm()
end

function state:slam()
	-- shake and play music
	S_StartSound(nil, sfx_dmga3)

	self.logoTween = 0
	self.logoMaxTween = 24
	self.logoTicker = 12
	self.logoPhase = 1
	self.whiteFade = 0

	S_ChangeMusic("FH_MPV", true)
end

function state:confirm()
	self.logoTween = 0
	self.logoMaxTween = 10
	self.logoTicker = 5
	self.logoPhase = 3

	S_FadeMusic(0, 15 * MUSICRATE / TICRATE)
end

FH.titleStates.intro = state