
local M = {}
local SM = require("ServiceManager")
---@class IotClass
---@field position CS.UnityEngine.Vector3
---@field showPosition CS.UnityEngine.Vector3
---@field showZoom number
---@field equipmentCode string
---@field parameterDataTime string
---@field parameterData table
---@field parameterName string
---@field parameterCode string
---@field parameterUnit string
---@field lookInfo table
---@field imgUrl string
---@field areaName string
---@field equipmentName string
---@field areaCode string
local IotClass = class()

function IotClass:UpdateFromServerData(serverData)
	self.position = CS.UnityEngine.Vector3(serverData.deliveryInfo.x, serverData.deliveryInfo.y, serverData.deliveryInfo.z)
	self.showPosition = CS.UnityEngine.Vector3(serverData.showInfo.x, serverData.showInfo.y, serverData.showInfo.z)
	self.showZoom = serverData.showInfo.zoom
	self.equipmentCode = serverData.equipmentCode
	self.parameterDataTime = serverData.parameterDataTime
	self.parameterData = serverData.parameterData
	self.parameterName = serverData.parameterName
	self.parameterCode = serverData.parameterCode
	self.parameterUnit = serverData.parameterUnit
	self.lookInfo = serverData.lookInfo
	self.imgUrl = serverData.imgUrl
	self.areaName = serverData.areaName
	self.equipmentName = serverData.equipmentName
	self.areaCode = serverData.areaCode
end

---@type table<string,IotClass>
local allIotData = {}
local BillBoards = {}
function M.Init()
	if BillBoards then
		for _,v in pairs(BillBoards) do
			CS.Extend.Asset.AssetService.Recycle(v)
		end
	end
	BillBoards = {}
	allIotData = {}
end

function M.GetData()
	return allIotData
end

function M.ParseFromServerData(serverData)
	local equipmentCode = serverData.equipmentCode
	if equipmentCode == nil then
		return
	end
	local iot = allIotData[equipmentCode]
	if not iot then
		iot = IotClass.new()
		allIotData[serverData.equipmentCode] = iot
	end
	local loader = _APP:GetCurrentState():GetStateLoader()
	iot:UpdateFromServerData(serverData)
	loader:LoadGameObjectAsync("Assets/Res/UI/DigitalSpace/BillBoard.prefab", function(gameObject)
		local sceneRoot = SM.GetUIService().GetLayerRoot("Scene")
		gameObject.transform:SetParent(sceneRoot, false)
		gameObject.transform.position = iot.showPosition
		gameObject.transform.localScale = CS.UnityEngine.Vector3.one * iot.showZoom/100
		local billboardText = gameObject.transform:Find("Content"):GetComponent(typeof(CS.TMPro.TextMeshProUGUI))
		local tittleText = gameObject.transform:Find("Tittle"):GetComponent(typeof(CS.TMPro.TextMeshProUGUI))
		billboardText.text = string.format("%s : <color=#005500> %s %s", iot.parameterName, tostring(iot.parameterData), iot.parameterUnit)
		tittleText.text = iot.equipmentName
		BillBoards[equipmentCode] = gameObject
	end,true)
	
end

return M