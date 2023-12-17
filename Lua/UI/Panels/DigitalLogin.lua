local LuaBindingBase = require("base.LuaBindingBase")
local binding = require("mvvm.binding")
local LuaMVVMBindingType = typeof(CS.Extend.LuaMVVM.LuaMVVMBinding)
local SM = require("ServiceManager")
local EventType = require("EventType")
local UIService = SM.GetUIService()
---@class UI.Panels.DigitalLogin : LuaBinding
local M = class(LuaBindingBase)

function M:start()
	local ipStr = CS.UnityEngine.PlayerPrefs.GetString("DigitalLoginIp", "http://clouds1.prisoi.com:7086")
	local idStr = CS.UnityEngine.PlayerPrefs.GetString("DigitalLoginId", "sunwukong")
	local context = binding.build({
		data = {
			ip = ipStr,
			id = idStr,
		}
	})
	self.context = context
	local mvvm = self.__CSBinding:GetComponent(LuaMVVMBindingType)
	mvvm:SetDataContext(context)
	self.global = SM.GetService(SM.SERVICE_TYPE.GLOBAL_EVENT).GetGlobalDispatcher()
	context:watch("alpha", function(alpha)
		_ServerEndData.GetAccountData().alpha = alpha
	end)
end

function M:OnLogin()
	self.global:DispatchEvent(EventType.DIGITAL_LOGIN, self.context.ip, self.context.id)
	UIService.Hide("DigitalLogin")
	CS.UnityEngine.PlayerPrefs.SetString("DigitalLoginIp", self.context.ip)
	CS.UnityEngine.PlayerPrefs.SetString("DigitalLoginId", self.context.id)
end

function M:SetStyle1()
	_APP.chatStytle = 1
end

function M:SetStyle2()
	_APP.chatStytle = 2
end

return M
