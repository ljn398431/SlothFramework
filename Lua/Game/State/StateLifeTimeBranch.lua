local LuaBindingBase = require("base.LuaBindingBase")
local SM = require("ServiceManager")
---@class Game.State.StateLifeTimeBranch : LuaBinding
local M = class(LuaBindingBase)

function M:awake()
	self.go = self.__CSBinding.gameObject
	self.playerManager = SM.GetService(SM.SERVICE_TYPE.PLAYER).GetPlayerManager()
	-- print("go ",self.go)
end

function M:destroy()
	local fallBranchTab = self.playerManager:GetBranchTab()
	for i = 1, #fallBranchTab do
		if fallBranchTab[i] == self.go then
			table.remove(fallBranchTab,i)
			break
		end
	end
end

return M