local M = {}
local scene = {
	id = 1,
	currentSceneId = ""
}

function M.Init()
	print("init scene data")
end

function M.GetData()
	return scene
end

return M