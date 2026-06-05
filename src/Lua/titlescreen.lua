FH.titleState = ""
FH.titleStates = {}
FH.keys = {
	up = {"joy12"},
	down = {"joy13"},
	left = {"joy14"},
	right = {"joy15"},
	accept = {"joy1"},
	back = {"joy2"}
}

function FH:isTitlescreenActive()
	return titlemapinaction and mapheaderinfo[titlemap].fh_titlescreen
end

function FH:getTitlescreenState()
	if not self:isTitlescreenActive() then return end

	return self.titleStates[self.titleState]
end

function FH:changeTitlescreenState(name, ...)
	local state = self:getTitlescreenState()
	local new = self.titleStates[name]

	if not new then return end

	if state and state.exit then
		state:exit(name)
	end

	if new.load then
		new:load(...)
	end

	self.titleState = name
end

addHook("ThinkFrame", function()
	if not FH:isTitlescreenActive() then return end

	local state = FH:getTitlescreenState()

	if not state then return end
	if not state.tick then return end

	state:tick(v)
end)
addHook("HUD", function(v)
	if not FH:isTitlescreenActive() then return end

	v.drawFill()

	local state = FH:getTitlescreenState()

	if not state then return end
	if not state.draw then return end

	state:draw(v)
end, "title")

addHook("KeyDown", function(event)
	if not FH:isTitlescreenActive() then return end

	local state = FH:getTitlescreenState()
	local result

	if state and state.pressed then
		print(event.name)
		local input

		for keyIndex, key in pairs(FH.keys) do
			for _, eventName in ipairs(key) do
				if eventName == event.name then
					input = keyIndex
					print(keyIndex.." pressed")
					break
				end
			end

			if input then
				break
			end
		end

		if input then result = state:pressed(input) end
	end

	if not result then
		return true
	end
end)

dofile("titlestates/intro.lua")
dofile("titlestates/menubase.lua")
dofile("titlestates/mainmenu.lua")
dofile("titlestates/noway.lua")

FH:changeTitlescreenState("intro")

addHook("GameQuit", function()
	FH:changeTitlescreenState("intro")
end)

addHook("MusicChange", function(old, new, mflags, loop, position, prefade, fadein)
	if not FH:isTitlescreenActive() then return end
	if not leveltime then return end

	if new == "_title" then
		return old, 0, true, S_GetMusicPosition(), 0, 0
	end
end)