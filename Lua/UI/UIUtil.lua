local M = {}
local floor, format = math.floor, string.format

function M.FormatPercentageValue(number)
	number = floor(number * 0.1)
	if number % 10 ~= 0 then
		return format("%.1f%%", number * 0.1)
	else
		return format("%d%%", number * 0.1)
	end
end

return M