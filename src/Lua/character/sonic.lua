FH.altSkins.sonic = true

-- skin fix
local frames = {
	[SPR2_DEAD] = A,
	[SPR2_EDGE] = B,
	[SPR2_FALL] = B,
	[SPR2_GASP] = A,
	[SPR2_PAIN] = A,
	[SPR2_RIDE] = A,
	[SPR2_ROLL] = D,
	[SPR2_RUN_] = D,
	[SPR2_SPNG] = A,
	[SPR2_STND] = A,
	[SPR2_WAIT] = B,
	[SPR2_WALK] = H
}
local replacements = {
	[SPR2_SKID] = SPR2_WALK,
	[SPR2_SPIN] = SPR2_ROLL
}

addHook("ThinkFrame", function()
	if not FH:isMode() then return end

	for player in players.iterate do
		if not player.heistRound then continue end
		if not player.mo then continue end
		if player.mo.skin ~= "sonic" then continue end
		if not player.heistRound.useSuper then continue end

		local curSpr = player.mo.sprite2 & FF_FRAMEMASK

		if replacements[curSpr] ~= nil then
			player.mo.sprite2 = ($ & ~FF_FRAMEMASK)|replacements[curSpr]
			curSpr = player.mo.sprite2 & FF_FRAMEMASK
		end
		if frames[curSpr] ~= nil then
			if player.mo.frame & FF_FRAMEMASK > frames[curSpr] then
				player.mo.frame = $ & ~FF_FRAMEMASK
			end
		end
	end
end)