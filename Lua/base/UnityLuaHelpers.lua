---base.UnityLuaHelpers
local M = {}

---@param go CS.UnityEngine.GameObject
---@param func function
function M.SetGameObjectRecursive(go, func)
	func(go)
	local t = go.transform
	for i = 0, t.childCount - 1 do
		M.SetGameObjectRecursive(t:GetChild(i).gameObject, func)
	end
end

return M