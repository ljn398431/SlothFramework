local AIActionBase = require("Game.Actions.AIActionBase")
local SM = require("ServiceManager")
local TickService = SM.GetTickService()
local cjson = require "cjson"
local EventType = require("EventType")

---@class Game.Actions.ChatTextAction
local M = class(AIActionBase)

function M:ctor(serverData)
	self.serverData = serverData
	self.duration = tonumber((serverData.duration or 0) / 1000)
	warn("ChatTextAction:ctor",table.dump_r(serverData))
end

function M:GetActionName()
	return "ChatTextAction"
end


function M:OnEnter()
	M.super.OnEnter(self)
	warn("ChatTextAction:OnEnter",table.dump_r(self.serverData),self.serverData.isSelf)
	SM.GetGlobalEventService().GetGlobalDispatcher():DispatchEvent(EventType.CHAT_MSG,self.serverData.content,
			self.serverData.isSelf)
end

-- 1,判断超时
function M:IsTimeOver()
	local isOver = false
	if self.duration > 0 then		
		isOver = TickService.realtimeSinceStartup > self.startTime + self.duration
	end
	return isOver
end

-- 2,执行更新 false 继续循环 true 执行OnLeave;
function M:OnUpdate()
	if not table.empty(self.subActionList) then
		--有一个是false就返回false
		local finished = true
		for i = 1, #self.subActionList do
			finished = self.subActionList[i]:OnUpdate() and finished
		end
		--全部都true
		return finished
	else
		if self.duration < 0 then
			return false
		end
		local deltaTime = TickService.deltaTime
		self.tickTime = self.tickTime + deltaTime
		if self.tickTime > self.duration then
			return true
		else
			return false
		end
	end
end

--enterTime和leaveTime都是子类的
function M:OnLeave(msg)
	if not table.empty(self.subActionList) then
		for i = 1, #self.subActionList do
			self.subActionList[i]:OnLeave(msg)
		end
		self.subActionList = {}
	end
end

function M:GetStartTime()
	return self.startTime
end

return M
