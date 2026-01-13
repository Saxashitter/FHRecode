local gamestate = {}
local skipTitlecard = false

gamestate.states = {
	character = dofile("gamestates/pregameStates/character.lua"),
	menus = dofile("gamestates/pregameStates/menus.lua"),
	waiting = dofile("gamestates/pregameStates/waiting.lua")
}
gamestate.timeLeft = 60 * TICRATE

-- view game.lua for gamestate documentation

function gamestate:init()
	FHR.pregameTimeLeft = self.timeLeft

	for player in players.iterate do
		if not player.hr then return end

		player.hr.stasis = true
	end
end

function gamestate:load()
	FH:changeMusic("FH_PRG")
	
	-- apply MF_NOTHINK to all mobjs to ensure nothing moves. do this once as well so we dont gotta worry about lag
	for mobj in mobjs.iterate() do
		mobj.__hasNoThink = mobj.flags & MF_NOTHINK > 0
		mobj.flags = $|MF_NOTHINK
	end
end

function gamestate:update()
	if FHR.pregameTimeLeft then
		FHR.pregameTimeLeft = $ - 1
	else
		self:switch()
		return
	end

	for player in players.iterate do
		if not player.hr then continue end

		player.hr.stasis = true

		if player.mo then
			player.mo.momx = 0
			player.mo.momy = 0
			player.mo.momz = 0
			player.mo.tics = -1
			player.mo.alpha = 0
		end
	end
end

function gamestate:switch()
	for player in players.iterate do
		if not player.hr then continue end

		player.hr.skin = player.skin
	end

	if skipTitlecard then
		FH:setGamestate("game")
		return
	end

	FH:setGamestate("titlecard")
end

function gamestate:canSwitch()
	local count = 0
	local finishedCount = 0

	for player in players.iterate do
		if not player.hr then continue end
		---@diagnostic disable-next-line: undefined-field
		if player.hasLeftServer then continue end

		count = $+1

		if player.hr.pregameState == "waiting" or player.hg.spectatorMode then
			finishedCount = $+1
		end
	end

	return finishedCount >= count
end

function gamestate:preUpdate()
end

function gamestate:playerUpdate(player)
	local inputRegister = 50/4

	local x, _ = FH:isMovePressed(player, inputRegister)
	local jump = FH:isButtonPressed(player, BT_JUMP)
	local spin = FH:isButtonPressed(player, BT_SPIN)

	-- TODO: actual states instead of if checks that are overly messy

	local state = self.states[player.hr.pregameState]

	if state then
		local result = state:playerUpdate(self, player)

		if result then
			local newState = self.states[result]
			player.hr.pregameState = result

			if newState and newState.enter then
				newState:enter(self, player)
			end
		end
	end
end

function gamestate:playerQuit()
	if self:canSwitch() then
		self:switch()
	end
end

FH.gamestates.pregame = gamestate