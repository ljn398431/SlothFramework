local M = {}
local tracker = {
	content = nil,
	fontColor = nil,
}

function M.Init()
	print("init news data")
end

function M.GetData()
	return tracker
end

return M