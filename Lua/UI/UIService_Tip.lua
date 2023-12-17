local M = require("UI.UIService")

---@type CS.Extend.Asset.AssetService
local AssetService = CS.Extend.Asset.AssetService
local GameObjectType = "LoadGameObjectAsync"
local LuaMVVMBindingType = typeof(CS.Extend.LuaMVVM.LuaMVVMBinding)
local EventSystem = CS.UnityEngine.EventSystems.EventSystem
---@type CS.UnityEngine.RectTransformUtility
local RectTransformUtility = CS.UnityEngine.RectTransformUtility
local Camera = CS.UnityEngine.Camera
-- local yield = coroutine.yield
-- local WaitForEndOfFrame = CS.UnityEngine.WaitForEndOfFrame

M.TipType = {
	ItemDescription = "UI/Module/Module_Common",
	SkillDescription = "UI/Module/Module_Skill_Explain"
}
local tapAnyHandler
local currentTip

function M.ShowTip(tipType, dataContext, options)
	local tipLayer = M.GetLayerRoot("Tip")

	local loadHandle = AssetService.Get():LoadGameObjectAsync(tipType)
	loadHandle:OnComplete("+", function()
		local screenPos
		if options.screenPosition then
			screenPos = options.screenPosition
		else
			screenPos = RectTransformUtility.WorldToScreenPoint(Camera.main, options.worldPosition)
		end
		local ref = loadHandle.Result
		local go = ref:Instantiate(tipLayer, false)
		ref:Dispose()
		local mvvm = go:GetComponent(LuaMVVMBindingType)
		mvvm:SetDataContext(dataContext)
		local root = go.transform
		currentTip = root

		local position = CS.LuaBattleTransformUtility.GetScreenPositionToRectTransformLocalPosition(screenPos, tipLayer)
		root.anchoredPosition = position

		tapAnyHandler = CS.ScreenTouchUtil.RequestAnyTouchCallback(function()
			if M._FindSelectableInParent(go) then
				return
			end
			M.HideTip()
		end, false)
	end)
end

function M._FindSelectableInParent(go)
	local selected = EventSystem.current.currentSelectedGameObject
	if not selected then
		return false
	end

	if selected == go then
		return true
	end
	
	local parent = selected.transform
	local t = go.transform

	while parent do
		if parent == t then
			return true
		end
		parent = parent.parent
	end
	return false
end

function M.HideTip()
	if tapAnyHandler then
		tapAnyHandler:Dispose()
		tapAnyHandler = nil
	end

	if not currentTip then
		return
	end

	AssetService.Recycle(currentTip)
	currentTip = nil
end

return M