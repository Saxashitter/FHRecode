--- @class heist_global_t
--- @field collectibles table
--- @field this table

--- @class player_t
--- @field heist heist_global_t?  -- may be nil until initialized

--- Initalizes the game round. Should be ran in MapChange.
--- @param nextMap number
function FH:roundInit(nextMap)
	
end

--- Initializes the player for Fang's Heist.
--- @param player player_t
function FH:playerInit(player)
    local t = {}
    
    t.collectibles = {}
    t.this = {}

    player.heist = t
end

--- Checks if the player is in a exit sector.
--- @param player player_t
function FH:isPlayerExiting(player)
	if player.mo.subsector.sector.specialflags & SSF_EXIT > 0 then
		return true
	end

	for fof in player.mo.subsector.sector.ffloors() do
		if player.mo.z < fof.bottomheight then continue end
		if player.mo.z+player.mo.height > fof.topheight then continue end
		if fof.sector.specialflags & SSF_EXIT == 0 then continue end

		return true
	end

	return false
end

--- @class heist_round_t

--- @class mobj_t
--- @field heist heist_round_t?

--- Initalizes the player's mobj for Fang's Heist.
--- @param mobj mobj_t
function FH:mobjInit(mobj)
	local t = {}

	mobj.heist = t
end

--- Main data-keeping function.
--- @param player player_t
addHook("PlayerThink", function(player)
	if not player.heist then
		FH:playerInit(player)
	end

	if FH:isPlayerExiting(player) then
		print("we leaving")
	end
end)