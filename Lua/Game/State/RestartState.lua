local StateBase = require("Game.State.StateBase")
---@class Game.State.RestartState : Game.State.StateBase
local M = class(StateBase)
local SM = require("ServiceManager")

function M:Enter()
	SM.Shutdown()
	_APP:Shutdown()
	CS.UnityEngine.SceneManagement.SceneManager.LoadScene("StartUp");
end

function M:GetStateName()
	return "RestartState"
end

function M:Update()

end

-- abstract
function M:Exit()
	--local sceneLoadManager = CS.Extend.SceneManagement.SceneLoadManager.Get()
	--sceneLoadManager:UnloadScene("Assets/Scenes/Landing.unity")
end

function M:GetIsReady()
	return false
end

return M