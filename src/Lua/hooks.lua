local hooks = {}
local returnTypes = {}

function returnTypes.boolean(old, new)
	if old then
		return true
	end

	if new then
		return true
	end

	return false
end

function returnTypes.number(old, new)
	return max(old or 0, new or 0)
end

function returnTypes.any(old, new)
	if new == nil then
		if old == nil then
			return false
		end

		return old
	end

	return new
end

function FH:makeHook(name, returntype)
	if hooks then
		return
	end

	hooks[name] = {
		global = {},
		typed = {},
		returntype = returnTypes[returntype or ""] or returnTypes.any
	}
end

function FH:addHook(name, func, extra)
	if not hooks[name] then
		error("Invalid Fang's Heist hook: "..name)
	end

	if extra == nil then
		table.insert(hooks[name].global, func)
	else
		if not hooks[name].typed[extra] then
			hooks[name].typed[extra] = {}
		end

		table.insert(hooks[name].typed[extra], func)
	end
end

local function runList(result, merge, list, ...)
	for _, fn in ipairs(list) do
		local r = {fn(...)}
		if #r > 0 then
			for i = 1, #r do
				result[i] = merge($, r[i])
			end
		end
	end
end

function FH:runHook(typeArg, name, ...)
	local def = hooks[name]
	if not def then return end
	
	local merge = def.returntype
	local result = {}

	runList(result, merge, def.global, ...)
	if typeArg and def.typed[typeArg] then
		runList(result, merge, def.typed[typeArg], ...)
	end
	
	return unpack(result)
end