--- If this returns true, the table contains whatever your function tries to check for, along with the key and value.
--- @param tbl table
--- @param func fun(value: any): boolean
--- @return boolean
--- @return number
--- @return any|nil
function FH:doesTableHave(tbl, func)
	for k, v in ipairs(tbl) do
		if func(v) then
			return true, k, v
		end
	end

	return false, 0, nil
end