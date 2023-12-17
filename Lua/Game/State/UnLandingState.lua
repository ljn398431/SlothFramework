local StateBase = require("Game.State.StateBase")
---@class Game.State.UnLandingState : Game.State.StateBase
local M = class(StateBase)
local SM = require("ServiceManager")

function M:Enter()
	if _ServerEndData.GetSocket() then
		_ServerEndData.GetSocket():Close()
	end
	local sceneLoadManager = CS.Extend.SceneManagement.SceneLoadManager.Get()
	sceneLoadManager:LoadSceneAsync("Assets/Scenes/UnLanding.unity", false, function()
	end)
	-- SM.GetUIService().AfterSceneLoaded()
	CS.UnityEngine.Application.targetFrameRate = 10
	_ServerEndData.GetSocket():SetPauseSocketEvent(true)
end

function M:Update()
end

function M:SocketStatusChanged()
end

function M:GetStateName()
	return "UnLanding"
end

function M:Exit()
	local sceneLoadManager = CS.Extend.SceneManagement.SceneLoadManager.Get()
	sceneLoadManager:UnloadScene("Assets/Scenes/UnLanding.unity")
	_APP:UpdateTargetFrameRate()
end

function M:GetIsReady()
	return false
end

return M