local SM = require("ServiceManager")
local ConfigService = SM.GetConfigService()
---@class Game.Equipment.EquipmentDB
---style,gender,colorVariant,EquipmentData
local M = class()


function M:ctor()
	self:InitEquipmentButtonList()
end

function M:InitEquipmentButtonList()
	local configRows = ConfigService.GetConfig("ButtonList")
	self.buttonItemsData = {}
	for _, v in ipairs(configRows) do
		self.buttonItemsData[v.Part] = {
			name = v.Name,
			take = v.Take,
			id = v.id
		}
	end
end

function M:InitEquipmentData()
	local configRows = ConfigService.GetConfig("EquipmentBase")
	self.EquipmentDataMap = {}
	for _, v in pairs(configRows) do
		local EquipmentType = v.EquipmentType
		local data = {
			id = v.id,
			equipTypeId = v.EquipmentType,
			sprite = string.format("UI/Icon/%s.png", self:_FormatStringIcon(v.Icon,"0"..v.Gender)),
			take = self.styleBtns[tonumber(v.EquipmentType)].take,
			colors = self:_LoadVariantData(v),
			paths = self:_LoadVariantPath(v)
		}
		if v.Style == tostring(index) then
			if v.Gender == "3" then
				table.insert(self.equipmentData[1][tonumber(EquipmentType)], data)
				table.insert(self.equipmentData[2][tonumber(EquipmentType)], data)
			else
				table.insert(self.equipmentData[tonumber(v.Gender)][tonumber(EquipmentType)], data)
			end
		end
	end
end

return M
