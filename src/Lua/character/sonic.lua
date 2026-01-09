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

addHook("ThinkFrame", function()
	if not FH:isMode() then return end

	for player in players.iterate do
		if not player.heistRound then continue end
		print("heistround")
		if not player.mo then continue end
		print("mo")
		if player.mo.skin ~= "sonic" then continue end
		print("is sonic")
		if not player.heistGlobal.useSuper then continue end
		print("alt skin enabled")

		local curSpr = player.mo.sprite2 & FF_FRAMEMASK

		if frames[curSpr] == nil then continue end
		print("noticing...")

		if player.mo.frame & FF_FRAMEMASK > frames[curSpr] then
			player.mo.frame = $ & ~FF_FRAMEMASK
			print("reset")
		end
	end
end)