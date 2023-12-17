local M = require("UI.UIService")
local ConfigService = require "ConfigService"
-- local LuaBindingClickEvent = CS.Extend.LuaBindingEvent.LuaBindingClickEvent
local Button = CS.UnityEngine.UI.Button
---@type CS.Extend.Asset.AssetService
local AssetService = CS.Extend.Asset.AssetService
local UIViewBaseType = typeof(CS.Extend.UI.UIViewBase)
local EventType = require("EventType")
local SM = require("ServiceManager")
local MessageBox

function M.ShowMsgBoxFormat(configName, handlerTable, contentText, layer)
	local ok,configs =  M.LoadAndValidateConfigs(configName)

	if not ok then
		-- Configs have errors...
		return
	end

	configs.content = contentText
	M._GenerateBox(handlerTable,configs,layer)
end

function M.ShowMsgBox(configName, handlerTable, layer)
	local ok,configs =  M.LoadAndValidateConfigs(configName)
	
	if not ok then
		-- Configs have errors...
		return
	end

	M._GenerateBox(handlerTable,configs,layer)
end

function M._GenerateBox(handlerTable,configs,layer)
	local msgBoxLayer = M.GetLayerRoot(layer or "Popup")
	local loadHandle = AssetService.Get():LoadGameObjectAsync(configs.prefab)
	loadHandle:OnComplete("+", function()
		local result = loadHandle.Result
		local msgBox = CS.UnityEngine.GameObject
		msgBox = result:Instantiate(msgBoxLayer, false):GetComponent(UIViewBaseType)
		if configs.hide == "1" then
			local GlobalDispatcher = SM.GetService(SM.SERVICE_TYPE.GLOBAL_EVENT).GetGlobalDispatcher()
			GlobalDispatcher:AddEventListener(EventType.ON_SCENE_UNLOAD, M.UnLoadScene, self)
			MessageBox = msgBox
		end
		result:Dispose();
		local contentLabel = msgBox.transform:Find("MessageBox/ContentText"):GetComponent(typeof(CS.TMPro.TMP_Text))
		contentLabel.text = configs.content
		for i = 1, 3 do
			M._ConfigButton(msgBox,
					configs.buttonTitles[i],
					"MessageBox/ButtonGroup/Button" .. i,
					handlerTable[i]
			)
		end
	end)
end

function M._ConfigButton(msgBox, buttonTitle, buttonObjPath, callBack)
	local buttonRoot = msgBox.transform:Find(buttonObjPath)
	if not M.NullOrEmpty(buttonTitle) then
		buttonRoot.gameObject:SetActive(true)
		local button = buttonRoot:GetComponent(typeof(Button))
		button.onClick:AddListener(function()
			if callBack then
				callBack()
			end
			M._HideMsgBox(msgBox)
		end)
		local buttonLabel = buttonRoot:Find("Text (TMP)"):GetComponent(typeof(CS.TMPro.TMP_Text))
		buttonLabel.text = buttonTitle
	else
		buttonRoot.gameObject:SetActive(false)
	end
end

function M.UnLoadScene()
	if MessageBox then
		M._HideMsgBox(MessageBox)
		local GlobalDispatcher = SM.GetService(SM.SERVICE_TYPE.GLOBAL_EVENT).GetGlobalDispatcher()
		GlobalDispatcher:RemoveEventListener(EventType.ON_SCENE_UNLOAD, M.UnLoadScene)
	end
end

function M._HideMsgBox(msgBox)
	AssetService.Recycle(msgBox)
	MessageBox = nil
end

function M.LoadAndValidateConfigs(configName)
	-- Rules:
	-- Must have a non-empty content string
	-- At least 1 button
	-- Each button must have a correspond callback
	-- At most 3 buttons. Params beyond the first 3 buttons would be omitted.
	-- Must have a non-empty prefab path
	local configs = {
		content = "",
		buttonTitles = {},
		prefab = "",
		hide = "1"
	}

	local configRows = ConfigService.GetConfig("MessageBox")
	if configRows[configName].content then
		configs.content = configRows[configName].content
	else
		error(string.format(
				"Dialog %s Error: Empty Content!", configName
		))
		return false,nil
	end

	local row = configRows[configName]
	for i = 1, 3 do
		if row["title" .. i] then
			configs.buttonTitles[i] = row["title" .. i]
		end
	end

	if configRows[configName].prefab then
		configs.prefab = configRows[configName].prefab
	else
		error(string.format(
				"Dialog %s Error: Empty Prefab Path!", configName
		))
		return false,nil
	end
	if configRows[configName].hide then
		configs.hide = configRows[configName].hide
	else
		error(string.format(
				"Dialog %s Error: Empty hide Value!", configName
		))
		return false,nil
	end
	return true,configs
end

function M.NullOrEmpty(str)
	return str == nil or str == ''
end

return M