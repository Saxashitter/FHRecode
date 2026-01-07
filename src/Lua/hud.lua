local MODNAME = "FH" -- unique identifier for customhud
local uis = {}

local uiMT = {
	x = 0,
	y = 0,
	flags = 0,
	visible = true,
	priority = 1,
	draw = function(self, v, player, camera) end
}
uiMT.__index = uiMT

function FH:getUI(name)
	for _, ui in pairs(uis) do
		if ui.name == name then
			return ui
		end
	end
	return false
end

function FH:addUI(ui, name, priority, hudtype)
	if type(ui) ~= "table" then return end
	if type(name) ~= "string" then return end

	priority = priority or 1
	hudtype = hudtype or "game"

	ui = setmetatable(ui, uiMT)
	ui.name = name
	ui.priority = priority

	-- Store reference
	uis[name] = ui

	-- customhud: higher layer = drawn later
	local drawlayer = priority

	customhud.SetupItem(
		name,               -- HUD item name
		MODNAME,            -- mod identifier
		function(v, player, camera)
			-- gating logic stays intact
			if not FH.uiEnabled then return end
			if not ui.visible then return end

			local gametype = FH:isMode()
			if not gametype then return end

			ui:draw(v, player, camera)
		end,
		hudtype,            -- game / scores / intermission / overlay
		drawlayer,
		2                   -- mod priority (simple replacement)
	)
end

local function doUiFile(filePath)
	local ui, name, priority, hudtype =
		dofile("hud/" .. filePath .. ".lua")

	if priority then
		-- allow modders to go behind built-ins
		priority = $ + 1
	end

	FH:addUI(ui, name, priority, hudtype)
end

function FH:setUIVisible(name, state)
	if not uis[name] then return end

	uis[name].visible = state

	if state then
		customhud.enable(name)
	else
		customhud.disable(name)
	end
end

function FH:isUIVisible(name)
	if not uis[name] then return false end
	return customhud.enabled(name)
end

FH.playerIconParallax =
	dofile("hud/reusable/playerIconParallax.lua")

-- menus
doUiFile("menus/titlecard")
doUiFile("menus/pregame")
doUiFile("menus/intermission")
doUiFile("menus/mapvote")
doUiFile("menus/rottenboy")

-- ingame
doUiFile("ingame/profit")
doUiFile("ingame/place")
doUiFile("ingame/timer")
doUiFile("ingame/health")
doUiFile("ingame/warning")

-- modifiers
doUiFile("ingame/modifiers/jumpscare")