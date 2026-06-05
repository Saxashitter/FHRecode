local state = setmetatable({}, FH.titleStates.menubase)

function state:load(fade)
	FH.titleStates.menubase.load(self)

	self.tween = 0
	self.maxTween = 10
	self.exiting = false
	self.fadeAway = fade == true

	S_ChangeMusic("FH_MNM", true)
	mapmusname = "FH_MNM"
end

function state:exit(state, fadeAway)
	if self.exiting then return end

	self.exiting = true
	self.tween = 0
	self.state = state
	self.fadeAway = false

	if fadeAway then
		S_FadeMusic(0, 6 * 1000 / 35)
		self.fadeAway = true
	end
end

local function placeholder(self)
	state:exit("noway", true)
end

state.items = {
	{
		name = "Open SRB2 Menu",
		desc = "Set your controls, host a server or load more mods.",
		selected = function()
			return true
		end
	},
	{
		name = "Campaign",
		desc = "A 6-stage campaign that plays out how YOU want it.\nOne hit, and you're out. Go for the high score!",
		selected = placeholder
	},
	{
		name = "Manual",
		desc = "Learn how to play the mod.",
		selected = placeholder
	},
	{
		name = "Achievements",
		desc = "View your achievements here!\nUnlocked either by playing Multiplayer or Campaign.",
		selected = placeholder
	},
	{
		name = "Settings",
		desc = "Tweak the mod to your liking before you host a server!\nThese remain changed even after you reload the mod.",
		selected = placeholder
	},
	{
		name = "Credits",
		desc = "Take a look at all the wonderful people who made this mod come to life!",
		selected = placeholder
	}
}

function state:tick()
	if self.tween < self.maxTween then
		self.tween = $ + 1
	end

	if self.exiting and self.tween == self.maxTween then
		FH:changeTitlescreenState(self.state)
	end
end

function state:draw(v)
	local tween = FixedDiv(self.tween, self.maxTween)
	if not self.exiting then
		tween = FU - $
	end

	-- ease
	tween = ease.inquad($, 0, 1000 * FU) / 1000

	local sw = v.width() * FU / v.dupx()
	local sh = v.height() * FU / v.dupy()

	local height = 11 * FU
	local padding = FU

	local x = 12 * FU
	local y = 100 * FU - ((height * #self.items) + (padding * (#self.items - 1))) / 2

	local offsetY = 12 * FU
	local textOffsetY = 2 * FU

	local selectedOffsetX = 8 * FU
	local selectedColor = V_YELLOWMAP

	local tail = v.cachePatch("FH_MENUTAIL")
	local tailHeight = tail.height * FU
	local flags = V_SNAPTOLEFT

	local background = v.cachePatch("FH_S2BACKGROUND")

	local tileW = background.width * FU
	local tileH = background.height * FU
	
	local bgOffsetX = (-leveltime * FU / 3) % tileW
	local bgOffsetY = (-leveltime * FU / 3) % tileH
	local bgTransparency = 0

	if self.fadeAway then
		bgTransparency = 10 * tween / FU
	end

	if bgTransparency < 10 then
		for y = bgOffsetY, sh, tileH do
			for x = bgOffsetX, sw, tileW do
				v.drawScaled(x, y, FU, background, V_SNAPTOLEFT|V_SNAPTOTOP|(bgTransparency * V_10TRANS))
			end
		end
	end

	local fang = v.cachePatch("CREDIT08")
	local fangWidth = fang.width
	local fangHeight = fang.height
	local fangMap = v.getColormap(TC_DEFAULT, SKINCOLOR_NONE, "FH_AllWhite")
	local fangScale = FixedDiv(180, fangHeight)
	local fangX = 320 * FU - 110 * FU + 160 * tween
	local fangY = 100 * FU - (fangHeight * fangScale / 2)
	local fangBorder = 2 * FU

	v.drawScaled(fangX - fangBorder, fangY - fangBorder, fangScale, fang, V_SNAPTORIGHT, fangMap)
	v.drawScaled(fangX + fangBorder, fangY - fangBorder, fangScale, fang, V_SNAPTORIGHT, fangMap)
	v.drawScaled(fangX + fangBorder, fangY + fangBorder, fangScale, fang, V_SNAPTORIGHT, fangMap)
	v.drawScaled(fangX - fangBorder, fangY + fangBorder, fangScale, fang, V_SNAPTORIGHT, fangMap)
	v.drawScaled(fangX, fangY, fangScale, fang, V_SNAPTORIGHT)

	for i, item in ipairs(self.items) do
		local selected = self.selection == i
		local stringWidth = SSL.getStringWidth(v, item.name, "STCFN%03d") * FU

		local x = x
		if selected then
			x = $ + selectedOffsetX
		end

		FH:drawPaletteRect(v, -160 * tween, y, x + stringWidth, tailHeight, 31, flags)
		v.drawScaled(x + stringWidth - 160 * tween, y, FU, tail, flags)
		SSL.drawFixedString(v, x - 160 * tween, y + textOffsetY, FU, item.name, "STCFN%03d", flags, 0, 0, (selected and selectedColor or 0))

		y = $ + offsetY
	end
end

function state:pressed(keyName)
	if self.exiting then return end

	if keyName == "back" then
		self:exit("intro", true)
		return
	end

	return FH.titleStates.menubase.pressed(self, keyName)
end

FH.titleStates.mainmenu = state