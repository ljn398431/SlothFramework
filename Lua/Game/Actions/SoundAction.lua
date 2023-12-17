local AIActionBase = require("Game.Actions.AIActionBase")
local SM = require("ServiceManager")
local TickService = SM.GetTickService()
local cjson = require "cjson"

---@class Game.Actions.SoundAction
local M = class(AIActionBase)
local AudioManager = CS.Extend.AudioManager

--serverData 数据,typeName 名字, parentAction 组合Action
function M:ctor(serverData)
    self.serverData = serverData
    self.duration = tonumber((serverData.duration or 0) / 1000)

    self.downloadComplete = false
    if string.startWith(serverData.voiceUrl, "http") then
        self.Uri = serverData.voiceUrl
    else
        self.Uri = serverData.voiceUrl
    end
    self.diffTime = 0
    self.downloadStartTime = TickService.realtimeSinceStartup
    AudioManager.Instance:DownLoadFile(self.Uri, function(data)
        self.downloadComplete = true
        self.diffTime = TickService.realtimeSinceStartup - self.downloadStartTime
    end)
    _APP.AI:SetTalk()
    self.isPlay = false
end

function M:GetActionName()
    return "SoundAction"
end

function M:GetActionBehaviourBitMask()
    return self.Conflict.AI_BEHAVIOR_TYPE_NONE
end

function M:OnEnter()
    M.super.OnEnter(self)
    if self.downloadComplete then
        AudioManager.Instance:PlayRemoteAudio(self.Uri)
        self.startTime = TickService.realtimeSinceStartup
    end
end

-- 1,判断超时
function M:IsTimeOver()
    local isOver = false
    if self.duration > 0 then
        isOver = TickService.realtimeSinceStartup > self.startTime + self.duration and self.downloadComplete
    end
    return isOver
end

-- 2,执行更新 false 继续循环 true 执行OnLeave;
function M:OnUpdate()
    if not self.downloadComplete then
        self.tickTime = 0
        if TickService.realtimeSinceStartup > self.downloadStartTime + self.duration then
            warn("voice data download time out")
            return true
        end
        return false
    end

    if not self.isPlay then
        AudioManager.Instance:PlayRemoteAudio(self.Uri)
        self.isPlay = true
    end

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

local AudioType = CS.Extend.AudioSourceType
--enterTime和leaveTime都是子类的
function M:OnLeave(log)
    if not table.empty(self.subActionList) then
        for i = 1, #self.subActionList do
            self.subActionList[i]:OnLeave(log)
        end
        self.subActionList = {}
    end
    AudioManager.Instance:Stop(AudioType.Speak)
end

function M:GetStartTime()
    return self.startTime
end

return M
