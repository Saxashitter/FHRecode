--- @class heistModifier_t
--- @field name string
--- @field description string
--- @field difficulty string
--- @field init fun(self: heistModifier_t)
--- @field update fun(self: heistModifier_t)
--- @field finish fun(self: heistModifier_t)

local heistModifier_t = {
	__index = nil,

	name = "Template",
	description = "The person didn't give this a description.",
	difficulty = "unknown",

	init = function() end,
	update = function() end,
	finish = function() end,
}
heistModifier_t.__index = heistModifier_t

function FH:returnModifierMetatable()
	return heistModifier_t
end

function FH:addModifier(modifier)
	local modifierTable = self.modifiers[modifier.class]

	if not modifierTable then
		return
	end

	table.insert(modifierTable, modifier)
	table.insert(self.modifiers.all, modifier)

	modifier.id = #self.modifiers.all
end

function FH:startModifier(modifier)
	
end