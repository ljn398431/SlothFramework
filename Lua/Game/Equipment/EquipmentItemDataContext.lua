local M = {}

---@class EquipmentItemDataContext
---@field id string
---@field name string
---@field isOn boolean
---@field tab string
---@field sprite CS.UnityEngine.Sprite
---@field bindListItem EquipmentListItem
---@field assetRef CS.UnityEngine.GameObject
---@field enabled boolean

local EquipmentItemDataContext = class()

function EquipmentItemDataContext:ctor(itemData, iconTexture, name, defaultIsOn, tab)
	self.id = itemData.Id
	self.name = name
	self.sprite = iconTexture
	self.reddot = itemData.IsNew
	self.isOn = defaultIsOn
	self.defaultIsOn = defaultIsOn
	self.tab = tab
	self.bindListItem = itemData
	self.enabled = true
end

---@param itemData EquipmentListItem
---@param tab string
---@param defaultIsOn boolean
---@return EquipmentItemDataContext
function M.ParseFromEquipData(itemData, tab, defaultIsOn)
	local spriteUri
	if not itemData.IsDiyItem then
		local folder = "Cloth"
		if itemData.Location == "face" then
			folder = "Face"
		end
		spriteUri = string.format("Assets/Res/UI/Icon/%s/%s", folder, itemData.IconPath)
	end
	if not tab then
		tab = itemData.Location
	end
	local dataContext = {
		id = itemData.Id,
		sprite = spriteUri,
		isOn = defaultIsOn,
		defaultIsOn = defaultIsOn,
		tab = tab,
		bindListItem = itemData,
		enabled = true,
		active = true,
	}
	return dataContext
end

return M
