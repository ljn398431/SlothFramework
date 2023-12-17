---@class Game.Equipment.AvatarEquipment
---@field EquipAll function
local M = class()
local AvatarUtil = CS.DigitalHuman.Avatar.AvatarUtil
local SM = require("ServiceManager")
local AssetService = CS.Extend.Asset.AssetService

function M:ctor(equipmentData, owner)
	self.equipmentDataMap = equipmentData
	self.owner = owner
	self.equipments = {}
	self.loadContexts = {}
end

function M:EquipAll(finishedCalback)
	if not self.equipmentDataMap then
		self.equipmentDataMap = {}
		return
	end
	
	for equipPartName, equipData in pairs(self.equipmentDataMap) do
		warn("EquipAll equipPartName", equipPartName)
		self:LoadEquipment(equipPartName, equipData, finishedCalback)
	end
end

---@param equipPartName string
---@param callback function | nil
function M:LoadEquipment(equipPartName, equipId, callback)
	if not equipPartName then
		error("equipPartName is nil")
	end
	local equipment = {equipPartName = equipPartName}
	local loader = _APP:GetCurrentState():GetStateLoader()
	local ConfigService = SM.GetConfigService()
	local equipmentConfig = ConfigService.GetConfigRow("EquipmentBase", equipId)
	if not equipmentConfig then
		warn("Equipment ConfigId Not Found", equipPartName, equipId)
		if callback then
			callback()
		end
		return
	end

	if equipPartName ~= equipmentConfig.EquipmentLocation then
		if callback then
			callback()
		end
		return
	end

	local assetPath = string.format("Assets/Res/Avatar/Clothes/%s", equipmentConfig.EquipmentPrefabName)
	local contextCallback = callback
	local oldLoadContext = self.loadContexts[equipPartName]
	if oldLoadContext then
		oldLoadContext.cancel = true
		--合并之前的callback，成功加载后一并回调，context的管理只是优化加载过程，不影响函数调用逻辑
		if oldLoadContext.callback then
			local oldCallback = oldLoadContext.callback
			if callback then
				contextCallback = function ()
					oldCallback()
					callback()
				end
			else
				contextCallback = oldCallback
			end
		end
	end

	local loadContext = loader:LoadGameObjectAsync(assetPath, function(go)
		print("load equipment", equipPartName, assetPath)
		equipment.go = go
		go.name = equipId
		AvatarUtil.SkinnedMeshAvatarBinding(self.owner:GetTransform(), go)
		go.transform:SetParent(self.owner:GetTransform(), false)
		local loaded = self.loadContexts[equipPartName].callback
		self.loadContexts[equipPartName] = nil

		if table.empty(self.loadContexts) then
			AvatarUtil.RemoveCache(self.owner:GetTransform())
		end
		
		local oldEquipment = self.equipments[equipPartName]
		if oldEquipment then
			self:ClearEquipment(oldEquipment)
		end
		self.equipments[equipPartName] = equipment
		if loaded then
			loaded()
		end
	end, true)
	loadContext.callback = contextCallback
	self.loadContexts[equipPartName] = loadContext
end

---@param data EquipmentData
---@return boolean
function M:HasEquip(data)
	if not self.equipmentDataMap then
		return false
	end
	for key, value in pairs(self.equipmentDataMap) do
		if value == data or value:EqualsIgnoreCustom(data) then
			return true
		end
	end
	return false
end

---@param other Game.Equipment.AvatarEquipment
---@return boolean
function M:Equals(other)
	if other == nil then
		return false
	end
	if table.count(other.equipmentDataMap) ~= table.count(self.equipmentDataMap) then
		return false
	end
	local isEqual = true
	for key, value in pairs(other.equipmentDataMap) do
		if self.equipmentDataMap[key] == nil then
			return false
		end
		local e = self.equipmentDataMap[key] == value
		if not e then
			isEqual = self.equipmentDataMap[key]:EqualsIgnoreCustom(value) and isEqual
		end
		if not isEqual then
			return isEqual
		end
	end
	return isEqual
end

function M:Unequip(name)
	local equipment = self.equipments[name]
	if equipment then
		self.equipments[name] = nil
		--先换头发再脱帽，防止秃头出现
		local Id = self.equipmentDataMap[name].ConfigId
		self.equipmentDataMap[name] = nil
		if name == "headWear" and self.equipmentDataMap.hair and M.HeadwearConflictWith(Id) then
			self:LoadEquipment("hair", self.equipmentDataMap.hair,function ()
				self:ClearEquipment(equipment)
			end)
		else
			self:ClearEquipment(equipment)
		end
	end
end

function M:ClearEquipment(equipment)
	equipment.go:SetActive(false)
	AssetService.Recycle(equipment.go)
end

function M:Destroy()
	if self.loadContexts then
		for _, loadContext in pairs(self.loadContexts) do
			if loadContext then
				loadContext.cancel = true
			end
		end
	end
	self.loadContexts = nil
	if self.equipments then
		for _, equipment in pairs(self.equipments) do
			self:ClearEquipment(equipment)
		end
	end
	self.equipments = nil
end

return M
