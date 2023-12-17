---@class UI.Panels.ToastManager
local M = {}
local LuaMVVMBindingType = typeof(CS.Extend.LuaMVVM.LuaMVVMBinding)
local UIViewBaseType = typeof(CS.Extend.UI.UIViewBase)
local AssetService = CS.Extend.Asset.AssetService
local toastIcons
local SM = require("ServiceManager")
local UIService = SM.GetUIService()

function M.SetIcons(icons)
	toastIcons = icons
end

function M.ShowTip(icon, content, duration)
	--通知native关闭弹窗
	duration = duration or 1
	local loader = _APP:GetCurrentState():GetStateLoader()
	if icon == "None" then
		loader:LoadGameObjectAsync(SM.GetConfigService().PathForFile("ToastNoIcon.prefab"), function(go)
			local popupRoot = UIService.GetLayerRoot("Popup")
			go.transform:SetParent(popupRoot, false)
			local mvvm = go:GetComponent(LuaMVVMBindingType)
			local context = { text = content }
			mvvm:SetDataContext(context)
			---@type CS.Extend.UI.UIViewBase
			local view = go:GetComponent(UIViewBaseType)
			view:Show()
			SM.GetTickService().Timeout({ start = duration, interval = duration }, 1, function()
				view:Hide(function()
					AssetService.Recycle(go)
				end)
			end)
		end, true)
	else
		loader:LoadGameObjectAsync(SM.GetConfigService().PathForFile("Toast.prefab"), function(go)
			local popupRoot = UIService.GetLayerRoot("Popup")
			go.transform:SetParent(popupRoot, false)
			local mvvm = go:GetComponent(LuaMVVMBindingType)
			local context = { text = content }
			if icon == "Info" then
				context.icon = toastIcons.info
			elseif icon == "Error" then
				context.icon = toastIcons.error
			end
			context.iconActive = context.icon ~= nil
			mvvm:SetDataContext(context)
			---@type CS.Extend.UI.UIViewBase
			local view = go:GetComponent(UIViewBaseType)
			view:Show()
			SM.GetTickService().Timeout({ start = duration, interval = duration }, 1, function()
				view:Hide(function()
					AssetService.Recycle(go)
				end)
			end)
		end, true)
	end
	
end

_ToastManager = M

return M
