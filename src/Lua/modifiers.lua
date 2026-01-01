--- @class heistModifier_t
--- @field name string
--- @field description string
--- @field type string
--- @field init fun(self: heistModifier_t)
--- @field update fun(self: heistModifier_t)
--- @field finish fun(self: heistModifier_t)
--- @field playerUpdate fun(self: heistModifier_t, player: player_t)
--- @field id number|nil

--- @type heistModifier_t
local heistModifier_t = {
	__index = nil,

	name = "Template",
	description = "The person didn't give this a description.",
	type = "main",

	init = function() end,
	update = function() end,
	finish = function() end,
	playerUpdate = function() end
}
heistModifier_t.__index = heistModifier_t

--- Returns the modifier metatable for modifier creation.
function FH:returnModifierMetatable()
	return heistModifier_t
end

--- Registers a modifier for the mode.
--- @param modifier heistModifier_t
--- @return heistModifier_t|nil
function FH:registerModifier(modifier)
	local modifierTable = self.modifiers.types[modifier.type]

	if modifierTable then
		table.insert(modifierTable, modifier)
	end
	table.insert(self.modifiers.all, modifier)

	modifier.id = #self.modifiers.all
	return modifier
end

--- Gets a modifier by it's name. Returns false if it's not valid.
--- @param name string
--- @return heistModifier_t|false
function FH:getModifier(name)
	for _, mod in ipairs(self.modifiers.all) do
		if mod.name == name then
			return mod
		end
	end

	return false
end

--- Returns true if this modifier is being used actively in the round.
--- @param modifier heistModifier_t
function FH:isModifierActive(modifier)
	for k, v in ipairs(FHR.modifiers) do
		if v == modifier.id then
			return true
		end
	end

	return false
end

--- Activates a modifier in the round.
--- @param modifier heistModifier_t
function FH:activateModifier(modifier)
	if FH:isModifierActive(modifier) then return end

	table.insert(FHR.modifiers, modifier.id)
	modifier:init()
end

--- Stops a modifier from being active.
--- @param modifier heistModifier_t
function FH:stopModifier(modifier)
	if not FH:isModifierActive(modifier) then return end

	for k, v in ipairs(FHR.modifiers) do
		if v == modifier.id then
			table.remove(FHR.modifiers, k)
			modifier:finish()
			break
		end
	end
end

COM_AddCommand("fh_activatemodifier", function(_, name)
	local modifier = FH:getModifier(name)
	if not modifier then return end

	FH:activateModifier(modifier)
	print("Activated modifier: "..name)
end, COM_ADMIN)

COM_AddCommand("fh_stopmodifier", function(player, name)
	local modifier = FH:getModifier(name)
	if not modifier then return end
	if not FH:isModifierActive(modifier) then return end

	FH:stopModifier(modifier)
end, COM_ADMIN)

-- get them modifiers
dofile("modifiers/main/bomb.lua")
dofile("modifiers/main/eggman.lua")

dofile("modifiers/side/airborne.lua")