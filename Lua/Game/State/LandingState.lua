local StateBase = require("Game.State.StateBase")
---@class Game.State.LandingState : Game.State.StateBase
local M = class(StateBase)
--local SEDService = require("Game.Network.ServerEndData.ServerEndDataService")
local SM = require("ServiceManager")

function M:Enter()
	self.ready = false
	local sceneLoadManager = CS.Extend.SceneManagement.SceneLoadManager.Get()
	sceneLoadManager:LoadSceneAsync("Assets/Scenes/Landing.unity", false, function()
	end)
	self.loaded = true
	self.frameCount = 0
	--if SEDService.GetSocket() then
	--	warn("Landing Loaded")
	--		SEDService.Login(M.AfterLogin, self)
	--	end
	--else
	--	SEDService.InitSocket()
	--end
end

function M:GetStateName()
	return "Landing"
end

function M:Update()
	if self.frameCount == 2 then
		local UIService = SM.GetService(SM.SERVICE_TYPE.UI)
		UIService.AfterSceneLoaded()
	end

	if self.frameCount == 240 then
		--if SEDService.GetSocket() then
		--	SEDService.Close()
		--end
		--SEDService.InitSocket()
	end
	self.frameCount = self.frameCount + 1
end

function M:SocketStatusChanged(status)
	if not self.loaded then
		return
	end
	warn("Connect status change", status)
end

-- abstract
function M:Exit()
	local sceneLoadManager = CS.Extend.SceneManagement.SceneLoadManager.Get()
	sceneLoadManager:UnloadScene("Assets/Scenes/Landing.unity")
end

function M:GetIsReady()
	return false
end

return M