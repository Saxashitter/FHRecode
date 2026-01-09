local FH = {altSkins = {}}

FH.altSkins.sonic = true

-- skin fix
local frames = {
    [SPR2_DEAD] = B,
    [SPR2_EDGE] = B,
    [SPR2_FALL] = B,
    [SPR2_GASP] = B,
    [SPR2_PAIN] = B,
    [SPR2_RIDE] = B,
    [SPR2_ROLL] = B,
    [SPR2_RUN_] = B,
    [SPR2_SPNG] = B,
    [SPR2_STND] = B,
    [SPR2_WAIT] = B,
    [SPR2_WALK] = B
}

addHook("ThinkFrame", function()
    for player in players.iterate do
        if not player.mo then continue end
        print("mo")
        if player.mo.skin ~= "sonic" then continue end
        print("is sonic")

		local curSpr = player.mo.sprite2 & FF_FRAMEMASK
		local curFrame = player.mo.frame & FF_FRAMEMASK

        print(SPR2_STND)
        print(curSpr)

        if frames[curSpr] == nil then continue end
        print("noticing...")

        if curFrame > frames[curSpr] then
			-- Archive this
            local flags = player.mo.frame & ~FF_FRAMEMASK
			player.mo.frame = A | flags
            print("reset")
        end
    end
end)