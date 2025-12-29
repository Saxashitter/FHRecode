-- local makeHook = MH._makeHook
-- local runHook = MH._runHook

-- makeHook("UI", "boolean")
-- makeHook("PostUI")

local uiMT = {
	x = 0,
	y = 0,
	flags = 0,
	visible = true,
	priority = 1,
	draw = function() end
}
uiMT.__index = uiMT

function FH:getUI(name)
	for hudtype, uis in pairs(self.uiElements) do
		for _, ui in ipairs(uis) do
			if ui.name == name then
				return ui
			end
		end
	end

	return false
end

function FH:addUI(ui, name, priority, hudtype)
	priority = $ or 1
	ui = setmetatable($, uiMT)
	hudtype = $ or "game"

	local key = #self.uiElements[hudtype]+1
	for i = 1, #self.uiElements[hudtype] do
		local curUi = self.uiElements[hudtype][i]

		if priority < curUi.priority then
			key = i
			break
		end
	end

	ui.name = name
	ui.priority = priority

	table.insert(self.uiElements[hudtype], key, ui)
end

function FH:drawHUD(v, player, camera, hudtype)
	for _, ui in ipairs(self.uiElements[hudtype]) do
		if not ui.visible then
			continue
		end

		-- if runHook(ui.name, "UI", v, player, camera, hudtype, ui) then
		-- 	runHook(ui.name, "PostUI", v, player, camera, hudtype, ui, true)
		-- 	continue
		-- end

		ui:draw(v, player, camera)
		-- runHook(ui.name, "PostUI", v, player, camera, hudtype, ui, false)
	end
end

addHook("HUD", function(v, player, camera)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end
	if not FH.uiEnabled then return end

	FH:drawHUD(v, player, camera, "game")
	FH:drawHUD(v, player, camera, "global")
end)

addHook("HUD", function(v)
	--- @type heistGametype_t|false
	local gametype = FH:isMode()
	if not gametype then return end
	if not FH.uiEnabled then return end

	local player = displayplayer

	FH:drawHUD(v, player, camera, "scores")
	FH:drawHUD(v, player, camera, "global")
end, "scores")

local function doUiFile(filePath)
	local ui, name, priority, hudtype = dofile("hud/"..filePath..".lua")

	if priority then
		-- modders may wanna put ui elements behind built-in ones
		-- allow them to do just that by making their priority 1
		priority = $ + 1
	end

	FH:addUI(ui, name, priority, hudtype)
end

--- require reusable hud objects and append them to FH
FH.playerIconParallax = dofile("hud/reusable/playerIconParallax.lua")

doUiFile("menus/pregame")
doUiFile("menus/intermission")
doUiFile("menus/titlecard")

doUiFile("ingame/timer")
doUiFile("ingame/health")