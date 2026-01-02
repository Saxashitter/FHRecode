freeslot("MT_FH_COLLECTIBLE", "S_FH_COLLECTIBLE")

local uncaughtFlags = MF_SPECIAL
local caughtFlags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOBLOCKMAP

FH.collectibleCommon = 0
FH.collectibleRare = 1
FH.collectibleExclusive = 2

---@class heistCollectible_t : mobj_t
---@field variant number                        # The variant of this collectible. (FH.collectibleCommon|FH.collectibleRare|FH.collectibleExclusive)
---@field overlay heistOverlay_t|nil            # The overlay. Only made valid when this is a rare or exclusive.
---@field sparkles heistSparkleController_t|nil # The sparkle controller. Only made valid when this is a rare or exclusive.
---@field target mobj_t|nil

---@diagnostic disable-next-line: missing-fields
mobjinfo[MT_FH_COLLECTIBLE] = {
	--$Title Collectible
	--$Category Fang's Heist - Items
	--$Sprite TRESI0
	--$Arg0 Variant (0-2)
	--$Arg1 Forced Frame (A-I)
	doomednum = 4097,
	spawnstate = S_FH_COLLECTIBLE,
	radius = 24 * FU / 2,
	height = 24 * FU,
	flags = uncaughtFlags
}

states[S_FH_COLLECTIBLE].sprite = freeslot("SPR_TRES")
states[S_FH_COLLECTIBLE].frame = 0
states[S_FH_COLLECTIBLE].tics = -1
states[S_FH_COLLECTIBLE].action = function(mobj)
	mobj.frame = ($ & ~FF_FRAMEMASK) | P_RandomRange(A, K)
end

--- @param player player_t
--- @param collectible heistCollectible_t
function FH:playerHasCollectible(player, collectible)
	player.heistRound.collectibles = player.heistRound.collectibles or {}

	for i, cur in ipairs(player.heistRound.collectibles) do
		if cur == collectible then
			return true, i
		end
	end

	return false, 0
end

--- @param player player_t
--- @param collectible heistCollectible_t
function FH:giveCollectible(player, collectible)
	if self:playerHasCollectible(player, collectible) then
		return false
	end

	player.heistRound.collectibles = player.heistRound.collectibles or {}
	table.insert(player.heistRound.collectibles, collectible)

	collectible.target = player.mo
	collectible.flags = caughtFlags
	collectible.momx = 0
	collectible.momy = 0
	collectible.momz = 0

	-- Position collectible on player's head, stacking multiple
	local dontSparkle = false
	local zoff = player.mo.height
	for i, col in ipairs(player.heistRound.collectibles) do
		if col == collectible then
			break
		end

		if col.variant > FH.collectibleCommon then
			dontSparkle = true
		end

		zoff = $ + col.height
	end

	if dontSparkle and collectible.sparkles and collectible.sparkles.valid then
		collectible.sparkles.stopSparkles = true
	end

	S_StartSound(collectible, sfx_s3k9f)
	S_StartSound(collectible, sfx_s3k68)
	P_SetOrigin(collectible, player.mo.x, player.mo.y, player.mo.z + zoff)

	FH:addProfit(player, FH.profitCVars.collectible.value + FH.profitCVars.collectibleExt.value * collectible.variant, "Collected Collectible")
	return true
end

--- @param player player_t
--- @param collectible heistCollectible_t
function FH:dropCollectible(player, collectible, launch)
	if launch == nil then launch = true end

	if not self:playerHasCollectible(player, collectible) then
		return false
	end

	if collectible.sparkles and collectible.sparkles.valid then
		-- ok start sparking
		collectible.sparkles.stopSparkles = false
		collectible.sparkles.ticker = 0
	end

	collectible.target = nil
	collectible.flags = uncaughtFlags
	if not launch then
		collectible.momx = 0
		collectible.momy = 0
		collectible.momz = 0
	else
		S_StartSound(collectible, sfx_cdfm67) -- SIX SEVEN SIX SEVENEENN SEINCIAIHLAFCHUAFHAFH RNO*WA WON EAHDSA S SIC XS ISVENVENUIAESALBFAUE NEUIANhio ueuiOAEHUIOVHAE UIODHSFUISDHF
		S_StartSound(collectible, sfx_s3k51)
		local angle = FixedAngle(FH:fixedRandom(0, 360*FU))
		local launchSpeed = FH:fixedRandom(16 * player.mo.scale, 36 * player.mo.scale)
		local launchZSpeed = FH:fixedRandom(0, 8 * player.mo.scale)

		P_InstaThrust(collectible, angle, launchSpeed)
		P_SetObjectMomZ(collectible, launchZSpeed)
	end

	FH:addProfit(player, -(FH.profitCVars.collectible.value + FH.profitCVars.collectibleExt.value * collectible.variant), "Lost Collectible")

	-- Remove from player list
	for i, cur in ipairs(player.heistRound.collectibles) do
		if cur == collectible then
			table.remove(player.heistRound.collectibles, i)
			break
		end
	end
	return true
end

--- @param mobj heistCollectible_t
addHook("MobjSpawn", function(mobj)
	mobj.variant = 0
	states[S_FH_COLLECTIBLE].action(mobj) -- dumb ass hack
end, MT_FH_COLLECTIBLE)

--- @param mobj heistCollectible_t
--- @param thing mapthing_t
addHook("MapThingSpawn", function(mobj, thing)
	mobj.variant = thing.args[0] or 0

	if mobj.variant == FH.collectibleRare then
		local overlay = P_SpawnMobjFromMobj(mobj, 0, 0, 0, MT_FH_OVERLAY) --[[@as heistOverlay_t]]
		overlay.alpha = FU / 3
		overlay.translation = "FH_AllBlue"
		overlay.target = mobj
		mobj.overlay = overlay

		local sparkles = P_SpawnMobjFromMobj(mobj, 0, 0, 0, MT_FH_SPARKLES) --[[@as heistSparkleController_t]]
		sparkles.target = mobj
		mobj.sparkles = sparkles
	elseif mobj.variant == FH.collectibleExclusive then
		local overlay = P_SpawnMobjFromMobj(mobj, 0, 0, 0, MT_FH_OVERLAY) --[[@as heistOverlay_t]]
		overlay.alpha = FU / 3
		overlay.translation = "FH_AllYellow"
		overlay.target = mobj
		mobj.overlay = overlay

		local sparkles = P_SpawnMobjFromMobj(mobj, 0, 0, 0, MT_FH_SPARKLES) --[[@as heistSparkleController_t]]
		sparkles.target = mobj
		mobj.sparkles = sparkles
	end
end, MT_FH_COLLECTIBLE)

--- @param collectible heistCollectible_t
--- @param toucher mobj_t
addHook("TouchSpecial", function(collectible, toucher)
	if collectible.target then return true end
	if not toucher.player then return true end
	if not toucher.health then return true end
	if P_PlayerInPain(toucher.player) then return true end
	if not FH:isMode() then return true end
	if not toucher.player.heistRound then return true end
	if toucher.player.heistRound.downed then return true end
	if toucher.player.heistRound.escaped then return true end -- TODO: gametype-based way to stop carriables from being carried instead of hardcoded bullshit

	FH:giveCollectible(toucher.player, collectible)
	return true
end, MT_FH_COLLECTIBLE)

--- @param collectible heistCollectible_t
addHook("MobjThinker", function(collectible)
	-- Animate overlay alpha if present
	if collectible.overlay and collectible.overlay.valid then
		collectible.overlay.alpha = abs(cos(FixedAngle((leveltime * FU) * 4))) / 3
	end

	-- Update position if attached to a player
	if not collectible.target then return end
	local player = collectible.target.player
	if not player then return end

	local zoff = player.mo.height
	for i, col in ipairs(player.heistRound.collectibles) do
		if col == collectible then
			break
		end
		zoff = $ + col.height
	end

	P_MoveOrigin(collectible, player.mo.x + player.mo.momx, player.mo.y + player.mo.momy, player.mo.z + zoff + player.mo.momz)
	collectible.angle = player.drawangle
end, MT_FH_COLLECTIBLE)
