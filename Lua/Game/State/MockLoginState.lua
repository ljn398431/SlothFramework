local StateBase = require("Game.State.StateBase")
local EventType = require("EventType")

---@class Game.State.MockLoginState : Game.State.StateBase
local M = class(StateBase)
local SM = require("ServiceManager")
local UIService = SM.GetUIService()
local TickService = SM.GetTickService()
-- abstract
function M:Enter()
end

function M:Login()
end

function M:Update()
end

function M:SocketStatusChanged()
end

function M:GetStateName()
	return "Login"
end

-- abstract
function M:Exit()
end

function M:GetIsReady()
	return self.ready
end

function M:GetStateType()
end

return M