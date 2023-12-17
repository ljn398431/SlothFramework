---@class UI.UIService
local M = {}
local layers = {}
local table, assert, typeof, pairs, ipairs = table, assert, typeof, pairs, ipairs
local AssetService = CS.Extend.Asset.AssetService
---@type CS.Extend.Asset.AssetService
local AssetServiceInstance = AssetService.Get()
local UILayer = CS.Extend.UI.UILayer
---@type CS.Extend.UI.CloseOption
local CloseOption = CS.Extend.UI.CloseOption
---@type UI.UIViewContext[]
local sortedElements = {}
---@type table<string, UI.UIViewContext>
local contexts = {}
local UIViewContext = require("UI.UIViewContext")
local SM = require("ServiceManager")
local UIViewConfiguration
local UIRoot
---@type CS.UnityEngine.Camera
local UICamera
local MainCamera
local uiLayerRef

function M.Init()
	UIViewConfiguration = require("UIViewConfiguration")
	uiLayerRef = AssetServiceInstance:LoadGameObject("UILayers.prefab")
	local go = uiLayerRef:Instantiate()
	UIRoot = go
	go.name = "UI"
	CS.UnityEngine.Object.DontDestroyOnLoad(go)

	local cameraRoot = go.transform:Find("LuaUICamera")
	UICamera = cameraRoot:GetComponent(typeof(CS.UnityEngine.Camera))
	UICamera.gameObject:SetActive(false)
	local transform = go.transform
	for i = 0, 5 do
		local childLayer = transform:GetChild(i)
		local canvas = childLayer:GetComponent(typeof(CS.UnityEngine.Canvas))
		local name = childLayer.name
		local layer = {
			transform = childLayer,
			go = childLayer.gameObject,
			name = name,
			elements = {},
			currentOrder = canvas.sortingOrder,
			canvas = canvas,
			layerIndex = i
		}
		--canvas.enabled = false
		local layerEnum = assert(UILayer.__CastFrom(name), name)
		layers[layerEnum] = layer
	end
	
	SM.GetTickService().RegisterLate(M.LateUpdate)
end

local CheckObjectDestroyed = CS.Extend.LuaUtil.UnityExtension4XLua.CheckObjectDestroyed

function M.LateUpdate()
	if not MainCamera or not CheckObjectDestroyed(MainCamera) or not UICamera then
		return
	end
	UICamera.transform.position = MainCamera.transform.position
	UICamera.transform.rotation = MainCamera.transform.rotation
end

function M.GetUICameraForwardVec()
	return UICamera.transform.forward
end

function M.GetUICameraPosition()
	return UICamera.transform.position
end

function M.GetUICamera()
	return UICamera
end

---@return CS.UnityEngine.RectTransform
function M.GetLayerRoot(name)
	local layerEnum = assert(UILayer.__CastFrom(name), name)
	return layers[layerEnum].transform
end

function M.SetUILayersActive(active)
	local list  = {"Transition","Popup","Dialog","MostTop","Tip"}
	for _,layer in ipairs(list) do
		M.GetLayerRoot(layer).gameObject:SetActive(active)
	end
end

function M.GetContext(name)
	return contexts[name]
end

function M.GetLoadedUI(name)
	local context = contexts[name]
	if not context then
		return
	end
	if context.status ~= "loaded" and context.status ~= "show" then
		return
	end
	return context.view
end

function M.AfterSceneLoaded()
	local camera = CS.UnityEngine.Camera.main
	MainCamera = camera
	local cameraData = camera:GetUniversalAdditionalCameraData()
	cameraData:AppendCamera(UICamera)
end

function M.BeforeSceneUnload()
	MainCamera = nil
end

local topFullScreenViewOrder = 0
---@param element UI.UIViewContext
function M._AddElement(element)
	local order = element.view.Canvas.sortingOrder
	local insertIndex
	for i, v in ipairs(sortedElements) do
		if v.view.Canvas.sortingOrder > order then
			table.insert(sortedElements, i, element)
			insertIndex = i
			break
		end
	end
	if not insertIndex then
		table.insert(sortedElements, element)
		insertIndex = #sortedElements
	end
	if element.configuration.FullScreen then
		if order > topFullScreenViewOrder then
			topFullScreenViewOrder = order
			for i = 1, insertIndex - 1 do
				local context = sortedElements[i]
				context.view:SetVisible(false)
				if context.bg then
					context.bg:SetVisible(false)
				end
			end
		end
	else
		if element.configuration.CloseMethod == CloseOption.Outside then
			assert(element.bg)
			local EventBinding = SM.GetService(SM.SERVICE_TYPE.EVENT_BINDING)
			local close; close = function()
				EventBinding.RemoveEventListener("OnClick", element.bg.gameObject, close)
				---@type CS.Extend.LuaBinding
				local binding = element.view:GetComponent(typeof(CS.Extend.LuaBinding))
				if binding then
					local closeFunc = binding.LuaInstance.Close
					if closeFunc then
						closeFunc(binding.LuaInstance)
						return
					end
				end

				M.Hide(element)
			end
			EventBinding.AddEventListener("OnClick", element.bg.gameObject, close)
		end
	end
end

function M._RemoveElement(element)
	local index
	for i, v in ipairs(sortedElements) do
		if v == element then
			table.remove(sortedElements, i)
			index = i
			break
		end
	end

	if not index then
		return
	end
	--[[ local showingCount = #sortedElements
	if showingCount == 0 then
		return
	end
	if showingCount == index - 1 then
		local topElement = sortedElements[showingCount]
		if not topElement.configuration.FullScreen then
			if topElement.configuration.CloseMethod == CloseOption.AnyWhere then

			end
		end
	end]]

	if element.configuration.FullScreen and element.view.Canvas.sortingOrder >= topFullScreenViewOrder then
		for i = index - 1, 1, -1 do
			local context = sortedElements[i]
			context.view:SetVisible(true)
			if context.bg then
				context.bg:SetVisible(true)
			end
			if context.configuration.FullScreen then
				topFullScreenViewOrder = context.view.Canvas.sortingOrder
				return
			end
		end
		topFullScreenViewOrder = 0
	end
end

function M.HasElement()
	return sortedElements[1] ~= nil
end

function M.Load(viewName, callback)
	if contexts[viewName] then
		warn("ui view exist : ", viewName)
		return
	end

	local configuration = UIViewConfiguration[viewName]
	local context = UIViewContext.new(configuration)
	context:Load(function(err, go)
		callback(err, go)
	end, layers)
	contexts[viewName] = context
	return context
end

---@alias Callback fun(err: string, go: CS.UnityEngine.GameObject)
---@param viewName string
---@param callback Callback
---@return UI.UIViewContext
function M.Show(viewName, callback)
	local context;
	context = M.Load(viewName, function(err, go)
		context:Show()
		if callback then
			callback(err, go)
		end
	end)
	return context
end

---@param context UI.UIViewContext | string
function M.Hide(context)
	if type(context) == "string" then
		local viewName = context
		if not contexts then
			warn("Try hide after app exit", viewName)
			return
		end
		context = contexts[viewName]
		if not context then
			warn("View ", viewName, "not exist")
			return
		end
		contexts[viewName] = nil
	else
		contexts[context.viewName] = nil
	end
	local layer = layers[context.configuration.AttachLayer]
	for i, v in ipairs(layer.elements) do
		if v == context then
			table.remove(layer.elements, i)
			break
		end
	end

	context:Hide()
	M._RemoveElement(context)
end

function M.CloseTopView()
	if #sortedElements <=0 then
		return false
	end
	local result = false
	for _,element in ipairs(sortedElements) do
		if not element or element.configuration.CloseMethod == CloseOption.None then
			result = false
		else
			local binding = element.view:GetComponent(typeof(CS.Extend.LuaBinding))
			if binding then
				local closeFunc = binding.LuaInstance.Close
				if closeFunc then
					closeFunc(binding.LuaInstance)
					result = true
					break
				end
			end

			M.Hide(element)
			result = true
			break
		end
	end
	return result
end

function M.clear()
	for _, context in pairs(contexts) do
		context:Destroy()
	end
	
	if UIRoot then
		AssetService.Recycle(UIRoot)
	end
	uiLayerRef:Dispose()
	contexts = {}
end

return M