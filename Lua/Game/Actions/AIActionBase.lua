local SM = require("ServiceManager")
local TickService = SM.GetTickService()
local cjson = require "cjson"

---@class Game.Actions.AIActionBase
local M = class()
M.Conflict = {
    AI_BEHAVIOR_TYPE_NONE = 0,
    AI_BEHAVIOR_TYPE_ANIMATION_UPPER = 1, --上半身动作
    AI_BEHAVIOR_TYPE_ANIMATION = 2, --全身动作
    AI_BEHAVIOR_TYPE_HEAD = 4, --头部动作
    AI_BEHAVIOR_TYPE_EMOTION = 16, --表情
    AI_BEHAVIOR_TYPE_VOICE = 64, --播放音频
    AI_BEHAVIOR_TYPE_REVERT = 2048 - 1, --清空上面的aciton
    AI_BEHAVIOR_TYPE_STATE = 2048, --AI状态
}

--serverData 数据,typeName 名字, parentAction 组合Action
function M:ctor(serverData, parentAction)
    self.serverData = serverData
    self.tickTime = 0
    self.duration = tonumber((serverData.duration or 0) / 1000)
    self.subActionList = {}
    if parentAction then
        parentAction:InsertSubActionList(self)
    end
end

function M:InsertSubActionList(action)
    warn("InsertSubActionList ", action:GetActionName())
    table.insert(self.subActionList, action)
end

function M:GetQueueName()
    return self.serverData.queueName
end

function M:GetActionName()
    error("GetActionName must be override")
end

function M:GetActionBehaviourBitMask()
    return self.Conflict.AI_BEHAVIOR_TYPE_NONE
end

function M:OnEnter()
    self.startTime = TickService.realtimeSinceStartup
    self.tickTime = 0
    --warn("OnEnter ",self:GetActionName())
    if not table.empty(self.subActionList) then
        warn("OnEnter ", self:GetActionName(), #self.subActionList)
        for i = 1, #self.subActionList do
            self.subActionList[i]:OnEnter()
        end
    end
end

function M:AppendStartTime(time)
    self.startTime = self.startTime + time
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
            self.subActionList[i]:OnLeave(log)
        end
        self.subActionList = {}
    end
end

function M:GetStartTime()
    return self.startTime
end

return M
