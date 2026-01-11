--- Moves 'current' toward 'target' by at most 'step'
--- @param current number
--- @param target number
--- @param step number
function FH:approach(current, target, step)
    if current < target then
        current = current + step

        if current > target then
            current = target
        end

    elseif current > target then
        current = current - step

        if current < target then
            current = target
        end
    end

    return current
end

--- Normalized time value from 0 to FRACUNIT
--- @param tics tic_t
--- @param duration tic_t
--- @param delay tic_t|nil
--- @return fixed_t
function FH:easeTime(tics, duration, delay)
	delay = delay or 0

	if duration <= 0 then
		return FRACUNIT
	end

	local t = tics - delay
	if t <= 0 then
		return 0
	end

	if t >= duration then
		return FRACUNIT
	end

	return FixedDiv(t, duration)
end

--- Gets a fixed random number from range.
--- @param start fixed_t
--- @param finish fixed_t
--- @return fixed_t
function FH:fixedRandom(start, finish)
	if start > finish then
		start, finish = finish, start
	end

	local range = finish - start
	return start + FixedMul(range, P_RandomFixed())
end

function FH:pointTo3DDist(x1, y1, z1, x2, y2, z2)
	return R_PointToDist2(0, z1, R_PointToDist2(x1, y1, x2, y2), z2)
end