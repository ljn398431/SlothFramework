---@class Game.Equipment.EquipmentData
local M = class()
---@class EquipmentDataClass
---@field id string
---@field location string
---@field gender string
---@field isOn boolean
---@field tab string
---@field sprite CS.UnityEngine.Sprite
local EquipmentDataClass = class()

function M:ctor()
	self.Id = id
end

function EquipmentDataClass:ctor(id,  iconTexture, defaultIsOn, clothLocation, clothType)
	self.id = id
	self.location = clothLocation
	self.isOn = defaultIsOn
	self.tab = clothType
	self.sprite = iconTexture
end

function M.ParseFromServerData(serverData)
	local id = serverData.Id
	local equipData = EquipmentDataClass.new(id, serverData.Icon, serverData.IsOn, serverData.Location, serverData.Tab)
	return equipData
end

return M
