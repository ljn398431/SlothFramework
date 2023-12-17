---@class Game.State.StateBase
local M = class()
local AssetService = CS.Extend.Asset.AssetService
local StateLifeTimeLoader = require("Game.State.StateLifeTimeLoader")

function M:PrepareEnter()
	self.loaderRef = AssetService.Get():LoadGameObject("StateLifeTimeLoader.prefab")
	self.loaderGO = self.loaderRef:Instantiate()
	self.loaderGO.name = "State-Loader"
	CS.UnityEngine.Object.DontDestroyOnLoad(self.loaderGO)
	self.loader = self.loaderGO:GetLuaBinding(StateLifeTimeLoader)
	self.exitRecycleGO = {}
end

function M:Enter()
end

function M:Update()
end

function M:GetStateName()
	error("Get State Name Not Implement")
end

function M:PrepareExit()
	AssetService.Recycle(self.loaderGO)
	self.loaderRef:Dispose()
end

---@return Game.State.StateLifeTimeLoader
function M:GetStateLoader()
	return self.loader
end

function M:Exit()
end

function M:GetIsReady()
	return false
end

function M:GetStateType()
end

return M