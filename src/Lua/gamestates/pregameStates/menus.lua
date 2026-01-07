local state = {}

-- i would put a to-do to refactor this but how would you even refactor it
-- ig its pretty clean as is

state.textSpacing = 8 * FU

local discord = "https://discord.gg/SBcg7ZFBuQ"

state.menus = {
	{
		name = "Ready?",
		state = "waiting",
		colors = {
			selected = V_GREENMAP
		}
	},
	{
		name = "Form Teams",
		submenu = {
			{
				name = "Teams are not in yet... Check back later!"
			}
		}
	},
	{
		name = "Press this to get the Discord server!",
		func = function(self, gamestate, player)
			CONS_Printf(player, "DISCORD LINK: https://discord.gg/SBcg7ZFBuQ")
			CONS_Printf(player, "Check your latest-log.txt to copy it!")
			S_StartSound(nil, sfx_bnce1, player)
		end
	}
}

--- @param player player_t
function state:getCurrentMenu(player)
    local menu = self.menus
    local path = player.heistRound.pregameMenuPath

    for i = 1, #path do
        menu = menu[path[i]].submenu
    end

    return menu
end


--- @param gamestate table
--- @param player player_t
function state:enter(gamestate, player)
	player.heistRound.pregameMenuLerp = (player.heistRound.pregameMenuSelection - 1) * self.textSpacing
end

--- @param gamestate table
--- @param player player_t
function state:playerUpdate(gamestate, player)
	local _, y = FH:isMovePressed(player, 50/4)
	local jump = FH:isButtonPressed(player, BT_JUMP)
	local spin = FH:isButtonPressed(player, BT_SPIN)
	local currentMenu = self:getCurrentMenu(player)

	if y ~= 0 then
		player.heistRound.pregameMenuSelection = $ - y

		if player.heistRound.pregameMenuSelection < 1 then
			player.heistRound.pregameMenuSelection = #currentMenu
		end
		if player.heistRound.pregameMenuSelection > #currentMenu then
			player.heistRound.pregameMenuSelection = 1
		end
	end

	if jump then
		 local item = currentMenu[player.heistRound.pregameMenuSelection]

        if item.submenu then
            table.insert(player.heistRound.pregameMenuPath, player.heistRound.pregameMenuSelection)

            player.heistRound.pregameMenuSelection = 1
			player.heistRound.pregameMenuLerp = (player.heistRound.pregameMenuSelection - 1) * self.textSpacing
        elseif item.func then
            item:func(gamestate, player)
		elseif item.state then
			return item.state
		end
	end

	if spin then
		if #player.heistRound.pregameMenuPath then
			table.remove(player.heistRound.pregameMenuPath, #player.heistRound.pregameMenuPath)
		else
			return "character"
		end
	end

	local targetY = (player.heistRound.pregameMenuSelection - 1) * self.textSpacing
	player.heistRound.pregameMenuLerp = ease.linear(FU / 3, player.heistRound.pregameMenuLerp, targetY)
end

--- @param v videolib
--- @param player player_t
function state:draw(gamestate, v, player)
	local menus = self:getCurrentMenu(player)
	local gamestate = FH.gamestates[FHR.currentState]

	local index = player.heistRound.pregameMenuSelection

	local startX = 160 * FU
	local startY = 110 * FU
	local spacing = self.textSpacing

	FH.playerIconParallax:draw(
		v,
		skins[player and player.skin or 0].name,
		leveltime
	)

	for i, menu in ipairs(menus) do
		local logicalY = (i - 1) * spacing
		local drawY = startY + logicalY - player.heistRound.pregameMenuLerp
		local selected = (i == index)

		local name = menu.name

		if menu.format then
			name = name:format(menu:format(gamestate, player))
		end

		local unselectedColor = menu.colors and menu.colors.unselected or V_GRAYMAP
		local selectedColor = menu.colors and menu.colors.selected or V_YELLOWMAP

		local color = selected and selectedColor or unselectedColor
		local width = SSL.getStringWidth(v, name, "TNYFN%03d") * FU

		-- selection arrow
		if selected then
			SSL.drawFixedString(v, startX - width / 2 - 4 * FU, drawY, FU, ">", "TNYFN%03d", 0, FU, FU/2, color, 0, 0)
		end

		-- menu text
		SSL.drawFixedString(v, startX, drawY, FU, name, "TNYFN%03d", 0, FU/2, FU/2, color, 0, 0)
	end

	local padding = 2
	SSL.drawString(v, 12, (200 - 12) - ((8 + padding) * 0), "[UP, DOWN] - Change Selection", "STCFN%03d", V_SNAPTOLEFT|V_SNAPTOBOTTOM, 0, FU, V_YELLOWMAP)
	SSL.drawString(v, 12, (200 - 12) - ((8 + padding) * 1), "[JUMP] - Select",               "STCFN%03d", V_SNAPTOLEFT|V_SNAPTOBOTTOM, 0, FU, V_YELLOWMAP)
	SSL.drawString(v, 12, (200 - 12) - ((8 + padding) * 2), "[SPIN] - Back",                 "STCFN%03d", V_SNAPTOLEFT|V_SNAPTOBOTTOM, 0, FU, V_YELLOWMAP)
end


return state