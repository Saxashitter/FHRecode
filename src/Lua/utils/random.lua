--- Returns randomized items from a table.
--- @param tbl table
--- @param amount number
--- @return table
function FH:randomItems(tbl, amount)
	local new = {}
	local selected = {}

	if #tbl == 0 then
		return selected
	end

	for i = 1, #tbl do
		new[i] = tbl[i]
	end

	for i = 1, amount do
		local item = P_RandomRange(1, #new)

		table.insert(selected, new[item])
		table.remove(new, item)

		if #new == 0 then break end
	end

	return selected
end