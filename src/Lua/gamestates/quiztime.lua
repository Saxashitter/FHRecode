-- one off state for the dylandude stream LOL

local gamestate = {}

gamestate.time = 30099 * TICRATE / MUSICRATE
gamestate.questions = {
	{
		question = "What's the release date of Sonic Blast\nin Japan?",
		answers = {
			"January 1st, 1988",
			"December 13, 1996",
			"October 2nd, 2000",
			"July 17th, 1992"
		},
		correct = 2
	},

	{
		question = "Which character is known as\nSonic's rival?",
		answers = {
			"Knuckles",
			"Metal Sonic",
			"Shadow",
			"Silver"
		},
		correct = 2
	},

	{
		question = "What is Dr. Eggman's\nreal name?",
		answers = {
			"Julian Robotnik",
			"Ivo Robotnik",
			"Gerald Robotnik",
			"Oscar Robotnik"
		},
		correct = 2
	},

	{
		question = "Which zone appears in\nSonic the Hedgehog 3?",
		answers = {
			"Mirage Island Zone",
			"Green Hill Zone",
			"Angel Island Zone",
			"Emerald Hill Zone",
		},
		correct = 2
	},

	{
		question = "How many Chaos Emeralds\nare there traditionally?",
		answers = {
			"Five",
			"Six",
			"Seven",
			"Eight"
		},
		correct = 3
	},

	{
		question = "What coding language does SRB2\nuse for it's modding functionality?",
		answers = {
			"C#",
			"Lua",
			"BLua",
			"Python"
		},
		correct = 3
	},

	{
		question = "Which engine does\nSRB2 run on?",
		answers = {
			"DOOM",
			"Quake",
			"DOOM Legacy",
			"GZDoom"
		},
		correct = 3
	},

	{
		question = "Which Mesaage Board judge is the\nmost prominent in the community?",
		answers = {
			"DylanDude",
			"Xian",
			"SonicX8000",
			"Pikaspoop",
		},
		correct = 1
	},

	{
		question = "Who voiced Sonic in SRB2 Final Demo?",
		answers = {
			"SSNTails",
			"Sonikku",
			"Rock the Bull",
			"Mystic"
		},
		correct = 3
	},

	{
		question = "In most cases, what is the cause for\nlaggy netgames?",
		answers = {
			"Too much players + unoptimized mods",
			"Big maps",
			"Bad internet",
			"Unsynchronized gamestate"
		},
		correct = 1
	},

	{
		question = "What is the unofficial\nSRB2 difficulty?",
		answers = {
			"Easy",
			"Normal",
			"Hard",
			"Extreme"
		},
		correct = 4
	},

	{
        question = "What's the release date of\nSonic Robo Blast v1.3f?",
        answers = {
            "April, 1998",
            "February, 1998",
            "January, 1999",
            "April, 1999"
        },
        correct = 2
    },

	{
		question = "What is Fang's Heist inspired by?",
		answers = {
			"Antonblast",
			"Pizza Tower",
			"SRB2",
			"Wario Land 4",
		},
		correct = 4
	},

	{
		question = "What breaks the game in most cases?",
		answers = {
			"Physics mods",
			"Character mods",
			"Gamemodes",
			"Source code mods"
		},
		correct = 1
	},

	{
		question = "What's the reason most\npeople rejoin net games?",
		answers = {
			"Hardware failures",
			"Chatbug",
			"Resync failure",
			"Getting kicked"
		},
		correct = 2
	},

	{
		question = "Train A, traveling 70 miles per hour (mph),\nleaves Westford heading toward Eastford,\n260 miles away. At the same\ntime Train B traveling 60 mph,\nleaves Eastford heading toward Westford.\nWhen do the two trains meet? How far\nfrom each city do they meet?",
		answers = {
			"67 hours",
			"2 hours",
			"what??",
			"idfk"
		},
		correct = 2
	},

	{
		question = "Which Sonic Game on Steam has\nthe largest file size?\n(Without DLC)",
		answers = {
			"Sonic X Shadow Generations",
			"Team Sonic Racing",
			"Sonic Frontiers",
			"Sonic Racing: Crossworlds"
		},
		correct = 3
	},

	{
		question = "Who's the person behind\nFang's Heist?",
		answers = {
			"Saxashitter",
			"Jisk",
			"Kirby Mania",
			"Me"
		},
		correct = 1
	}
}

function gamestate:init()
	self.cachedSongPosition = S_GetMusicPosition() -- used for when we get outta this

	FHR.quizHelp = $ or {}
	FHR.quizLastMusic = FHN.globalMusic
	FHR.quizTime = self.time

	local index = self:pickQuizQuestion(self.questions)
	FHR.quizQuestion = self.questions[index]

	FH:changeMusic("FH_QZT")

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

	for player in players.iterate do
		if not player.heistRound then continue end

		player.heistRound.stasis = true
		player.heistRound.quizTimeSelection = P_RandomRange(1, #FHR.quizQuestion.answers)
		player.heistRound.quizTimeSelected = false
	end
end

function gamestate:load()
end

function gamestate:update()
	FHR.quizTime = $ - 1

	if not FHR.quizTime then
		self:switch()
		return
	end

	for player in players.iterate do
		if not player.heistRound then continue end

		player.heistRound.stasis = true

		if player.mo then
			player.mo.momx = 0
			player.mo.momy = 0
			player.mo.momz = 0
		end
	end
end

function gamestate:switch()
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

		if mobj.player and mobj.player.valid then
			P_MovePlayer(mobj.player)
		end
	end
	for player in players.iterate do
		if not player.heistRound then continue end

		player.heistRound.stasis = false
		player.cmd.sidemove = player.heistGlobal.sidemove
		player.cmd.forwardmove = player.heistGlobal.forwardmove
		player.cmd.buttons = player.heistGlobal.buttons
		player.lastbuttons = player.heistGlobal.buttons

		if player.cmd.buttons & BT_JUMP then
			player.pflags = $|PF_JUMPDOWN
		end
		if player.cmd.buttons & BT_SPIN then
			player.pflags = $|PF_SPINDOWN
		end
	end

	FH:changeMusic(FHR.quizLastMusic)

	S_SetInternalMusicVolume(0)
	S_FadeMusic(100, 1000)

	if self.cachedSongPosition ~= nil then
		S_SetMusicPosition(self.cachedSongPosition)
	end

	FH:setGamestate("game", true)

	for player in players.iterate do
		if not player.heistRound then continue end
		if player.heistRound.spectator then continue end
		if player.heistRound.escaped then continue end
		if not player.mo then continue end

		if player.heistRound.quizTimeSelection ~= FHR.quizQuestion.correct or player.heistRound.quizTimeSelected == false then
			P_DamageMobj(player.mo, nil, nil, 100, DMG_INSTAKILL)
		end
	end
end

function gamestate:safeSwitch()
	local count = 0
	local selectedCount = 0

	for player in players.iterate do
		if not player.heistRound then continue end
		if player.heistRound.spectator then continue end
		if player.heistRound.escaped then continue end
		if player.hasLeftServer then continue end

		count = $ + 1
		if player.heistRound.quizTimeSelected then
			selectedCount = $ + 1
		end
	end

	if count == selectedCount then
		self:switch()
		return true
	end

	return false
end

function gamestate:preUpdate() end

--- @param player player_t
function gamestate:playerUpdate(player)
	local x, _ = FH:isMovePressed(player, 50/4)
	local selected = FH:isButtonPressed(player, BT_JUMP)
	local unselected = FH:isButtonPressed(player, BT_SPIN)

	if x ~= 0 and not player.heistRound.quizTimeSelected then
		player.heistRound.quizTimeSelection = $ + x

		if player.heistRound.quizTimeSelection < 1 then
			player.heistRound.quizTimeSelection = #FHR.quizQuestion.answers
		end
		if player.heistRound.quizTimeSelection > #FHR.quizQuestion.answers then
			player.heistRound.quizTimeSelection = 1
		end

		S_StartSound(nil, sfx_kc39, player)
	end

	if selected and not player.heistRound.quizTimeSelected then
		player.heistRound.quizTimeSelected = true
		S_StartSound(nil, sfx_kc5e, player)
		-- self:safeSwitch()
	end
end

--- @param player player_t
function gamestate:playerQuit(player)
	self:safeSwitch()
end

function gamestate:pickQuizQuestion(questions)
	local totalWeight = 0
	local pool = {}

	for i = 1, #questions do
		local q = questions[i]
		local base = q.weight or 100
		local picked = FHR.quizHelp[i] or 0

		-- adaptive decay
		local effective = base / (1 + picked)

		if effective > 0 then
			totalWeight = $ + effective
			pool[#pool + 1] = {
				index = i,
				weight = effective
			}
		end
	end

	-- ultra-safe fallback
	if totalWeight == 0 then
		return P_RandomRange(1, #questions)
	end

	local roll = P_RandomRange(1, totalWeight)
	local acc = 0

	for _, entry in ipairs(pool) do
		acc = $ + entry.weight
		if roll <= acc then
			-- mark pick
			FHR.quizHelp[entry.index] = (FHR.quizHelp[entry.index] or 0) + 1
			return entry.index
		end
	end
end

FH.gamestates.quiztime = gamestate

COM_AddCommand("quiz", function()
	FH:setGamestate("quiztime", false)
end, COM_ADMIN)