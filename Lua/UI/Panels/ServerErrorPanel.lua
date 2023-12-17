local LuaBindingBase = require("base.LuaBindingBase")
---@class UI.Panels.ServerErrorPanel : LuaBinding
---@field content CS.TMPro.TextMeshProUGUI
local M = class(LuaBindingBase)
local SM = require("ServiceManager")

function M:Setup(text)
	self.content.text = text
end

function M:OnClose()
	SM.GetUIService().Hide("ServerErrorPanel")
	if _APP.native then
	else
		local MockLoginState = require("Game.State.MockLoginState")
		_APP:Switch(MockLoginState.new())
		_ServerEndData.GetSocket():Close()
	end
end

return M