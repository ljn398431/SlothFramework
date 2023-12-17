local LuaBindingBase = require("base.LuaBindingBase")
---@class Game.State.StateLifeTimeLoader : LuaBinding
local M = class(LuaBindingBase)
local AssetService = CS.Extend.Asset.AssetService

function M:awake()
	self.exitRecycleGO = {}
end

function M:RegisterExitRecycleGO(go)
	self.exitRecycleGO[go] = 1
end

function M:UnregisterExitRecycleGO(go)
	self.exitRecycleGO[go] = nil
end

function M:destroy()
	for go, _ in pairs(self.exitRecycleGO) do
		AssetService.Recycle(go)
	end
	self.exitRecycleGO = nil
end

return M