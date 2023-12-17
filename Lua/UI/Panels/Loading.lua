local LuaBinding = require("base.LuaBindingBase")
local SM = require("ServiceManager")

---@class UI.Panels.Loading : LuaBinding
---@field tip CS.TMPro.TextMeshProUGUI
local M = class(LuaBinding)

function M:Show()
	if self.shown then
		return
	end
	local tipConfig = SM.GetConfigService().GetConfig("LoadingTips")
	local totalWeight = 0
	for _, row in pairs(tipConfig) do
		totalWeight = totalWeight + row.weight
	end
	local weight = math.random() * totalWeight
	totalWeight = 0
	for _, row in pairs(tipConfig) do
		totalWeight = totalWeight + row.weight
		if totalWeight > weight then
			self.tip.text = string.replace(row.content, "\\n", "\n")
			break
		end
	end

	self.__CSBinding.gameObject:SetActive(true)
	self.shown = true
end

function M:Hide()
	self.__CSBinding.gameObject:SetActive(false)
	self.shown = false
end

return M