-- one off state for the dylandude stream LOL

local gamestate = {}

gamestate.rottenBoyLength = 28291 * TICRATE / MUSICRATE
gamestate.rottenBoyTiming = {
	{0, 1413}, -- this is what we couldve had
	{1812, 3611}, -- this is what we couldve fuckin had
	{4255, 5376}, -- but dylannounce
	{5691, 6902}, -- being the woke shithead
	{7406, 8946}, -- thought it was too scary
	{9317, 10220}, -- so he changed it
	{10535, 11487}, -- to be for kids
	{11648, 11823}, -- uh
	{12957, 13629}, -- FUUUUUUUUUUCK
	{14140, 15750}, -- I HATE FANGS HEIST
	{16219, 17059}, -- AND I HATE
	{17269, 18522}, -- MILES PROWER
	{18935, 21224}, -- rotten boy ungrateful boy
	{21763, 23072}, -- ROTTEN BOOOOOOOOOOOOOOY
	{23373, 24367}, -- ROTTEN BOOOY
	{24661, 25690}, -- UNGRATEFUL BOOOOY
	{26005, 27636} -- I HATE MILES PROWER
}

local defaultScale = FU / 4
local addOn = FU / 12

freeslot("sfx_fh_dyl")

local function isInTiming()
	local progress = (gamestate.rottenBoyLength - FHR.rottenBoyLength) * MUSICRATE / TICRATE

	for k, v in ipairs(gamestate.rottenBoyTiming) do
		if progress >= v[1] and progress <= v[2] then
			return true
		end
	end

	return false
end

function gamestate:init()
	S_SetInternalMusicVolume(0)

	FHR.rottenBoyLength = self.rottenBoyLength
	FHR.rottenBoyXScale = defaultScale
	FHR.rottenBoyYScale = defaultScale

	S_StartSound(nil, sfx_fh_dyl)

	for mobj in mobjs.iterate() do
		mobj.__stopped = true
		mobj.__momx = mobj.momx
		mobj.__momy = mobj.momy
		mobj.__momz = mobj.momz
		mobj.__noThink = mobj.flags & MF_NOTHINK == 0

		mobj.momx = 0
		mobj.momy = 0
		mobj.momz = 0
		mobj.flags = $|MF_NOTHINK
	end
end

function gamestate:load()
	
end

function gamestate:update()
	FHR.rottenBoyLength = $ - 1

	if not FHR.rottenBoyLength then
		for mobj in mobjs.iterate() do
			if not mobj.__stopped then continue end

			mobj.momx = mobj.__momx
			mobj.momy = mobj.__momy
			mobj.momz = mobj.__momz
			if mobj.__noThink then
				mobj.__noThink = nil
				mobj.flags = $ & ~MF_NOTHINK
			end
			mobj.__stopped = nil
		end
		for player in players.iterate do
			if not player.heistRound then continue end

			player.heistRound.stasis = false
		end
		S_SetInternalMusicVolume(100)
		FH:setGamestate("game", true)
		return
	end

	for player in players.iterate do
		if not player.heistRound then continue end

		player.heistRound.stasis = true

		if player.mo then
			player.mo.momx = 0
			player.mo.momy = 0
			player.mo.momz = 0
			player.mo.tics = -1
		end
	end

	if isInTiming() then
		FHR.rottenBoyXScale = ease.linear(FU / 3, $, defaultScale - addOn)
		FHR.rottenBoyYScale = ease.linear(FU / 3, $, defaultScale + addOn)
	else
		FHR.rottenBoyXScale = ease.linear(FU / 3, $, defaultScale)
		FHR.rottenBoyYScale = ease.linear(FU / 3, $, defaultScale)
	end
end

function gamestate:preUpdate() end
function gamestate:playerUpdate() end
function gamestate:playerQuit() end

FH.gamestates.rottenboy = gamestate

COM_AddCommand("dont_tell_dylan", function()
	FH:setGamestate("rottenboy", false)
end, COM_ADMIN)