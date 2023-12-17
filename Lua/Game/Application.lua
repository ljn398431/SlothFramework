---@class Game.Application
local M = class()
local SM = require("ServiceManager")
local MockLoginState = require("Game.State.MockLoginState")
--local SEDService = require("Game.Network.ServerEndData.ServerEndDataService")
local ns = SM.GetService(SM.SERVICE_TYPE.NATIVE)
local UIService = SM.GetService(SM.SERVICE_TYPE.UI)
local MsgBox = require("UI.Panels.MessageBox")
local RestartState = require("Game.State.RestartState")
--local BuildingInteractive = require("Game.Building.BuildingInteractive")
local EventType = require("EventType")
local cjson = require("cjson")
local AssetService = CS.Extend.Asset.AssetService
local VersionService = CS.LifeGlory.Service.VersionService
local ConfigService = SM.GetConfigService()

_APP_VERSION = "1.0.2"
_APP_LUA_VERSION = "1.0.2"
_APP_RES_VERSION = "1.0.2"
_APP_NATIVE_VERSION = "2.3.0"

local ToastManager = require("UI.Panels.ToastManager")
local CoroutineAssetLoader = require("base.asset.CoroutineAssetLoader")

function M:ctor()
	_APP = self
	_G["sceneParten"] = "Assets/Scenes/%s.unity"
	self.isShutDown = false
	self.global = SM.GetGlobalEventService().GetGlobalDispatcher()
	local row = assert(ConfigService.GetConfigRow("WebRequest", "zhaoyuanHead"), "zhaoyuanHead")
	self.urlHead = row.url
	self.chatStytle = 1
	self.areaMap = {}
end

function M:Init()
	self.currentState = nil
	--self:Switch(LoginState.new())
	
	local service = SM.GetService(SM.SERVICE_TYPE.TICK)
	service.Register(M.Tick, self)
end

local UnLandingState = require("Game.State.UnLandingState")
function M:UnLanding()
	warn("Native UnLanding")
	self:Switch(UnLandingState.new())
end

function M:Tick()
	local ok, err = xpcall(_ServerEndData.Tick, debug.traceback)
	if not ok then
		error(err)
	end

	if not self.currentState then
		return
	end
	if self.stateSwitching then
		if not self.currentState:GetIsReady() then
			return
		else
			self.stateSwitching = false
			--self.loading:Hide()
			warn("State Ready", self.currentState:GetStateName())
			self:Dispatch(EventType.LOADING_UI_HIDE)
		end
	end

	self.currentState:Update()
end

---@return Game.State.StateBase
function M:GetCurrentState()
	return self.currentState
end

function M:_PerformSwitch(state, param)
	if self.currentState and state and self.currentState:GetStateName() == state:GetStateName() then
		warn("Same state repeat switch", state:GetStateName())
		return
	end
	
	self.stateSwitching = true
	SM.GetUIService().BeforeSceneUnload()
	if self.currentState then
		self.currentState:PrepareExit()
		self.currentState:Exit()
		self.currentState = nil
	end

	self.currentState = state
	if self.currentState then
		warn("Entering", self.currentState:GetStateName())
		CS.UnityEngine.Resources.UnloadUnusedAssets()
		self.currentState:PrepareEnter()
		self.currentState:Enter(table.unpack(param))
	end
end

function M:SetRedDot(info)
	if not self.redDotNativeInfo then
		self.redDotNativeInfo = {}
	end
	self.redDotNativeInfo[info["Name"]] = info
	self:Dispatch("UPDATE_UI_REDOT")
end

function M:Dispatch(typ,data)
	if self.global then
		self.global:DispatchEvent(typ,data)
	end
end

---@param state Game.State.StateBase
function M:Switch(state, ...)
	if self.currentState == state then
		return
	end

	local param = table.pack(...)
	--self:Dispatch(EventType.ON_SCENE_UNLOAD)
	--self.loading:Show()
	self:_PerformSwitch(state, param)
end

function M:Shutdown()
	if self.isShutDown then
		return
	end
	self:Switch(nil)
	self.isShutDown = true
end

return M
