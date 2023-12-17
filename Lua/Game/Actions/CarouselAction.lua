local AIActionBase = require("Game.Actions.AIActionBase")
local QuestionTitleAction = require("Game.Actions.QuestionTitleAction")
local QuestionAction = require("Game.Actions.QuestionAction")
local CarouselResetAction = require("Game.Actions.CarouselResetAction")

---@class Game.Actions.CarouselAction
local M = class(AIActionBase)
local SM = require("ServiceManager")
local TickService = SM.GetTickService()
local ActionService = SM.GetService("ActionService")
local cjson = require "cjson"

--serverData 数据,typeName 名字, parentAction 组合Action
function M:ctor(serverData)
    self.duration = 0
    warn("CarouselAction:ctor", serverData.backgroundImg, serverData.title)
    self.owner = _APP.AI
    self.owner:RemoveAllQueueAction()
    serverData["queueName"] = "Carousel"
    self:_BuildAction(serverData)
    _APP.AI.carousel = true
    self.owner:AddActionToQueue(self)
end

function M:_BuildAction(serverData)
    for _, question in ipairs(serverData.questionList) do
        warn("_BuildAction", question.answers, question.content)
        local titleAction = QuestionTitleAction.new({ duration = 100, content = question.content,
                                                      queueName = "Carousel" ,qId = question.qId})
        self.owner:AddActionToQueue(titleAction)
        for _,answer in ipairs(question.answers) do
            answer["queueName"] = "Carousel"
            local action = QuestionAction.new(answer)
            self.owner:AddActionToQueue(action)
        end
        --ActionService:NewAction("SoundAction", { content = question.content, duration = 100 ,queueName = "Carousel"})
        --local action = TextAndImageAction.new()
    end
    local resetAction = CarouselResetAction.new({ duration = 100, queueName = "Carousel" ,callback = function()
        self.duration = 0
        self.owner = _APP.AI
        self.owner:RemoveAllQueueAction()
        serverData["queueName"] = "Carousel"
        self:_BuildAction(serverData)
        self.owner:AddActionToQueue(self)
    end})
    self.owner:AddActionToQueue(resetAction)
end

function M:GetActionName()
    return "CarouselAction"
end

function M:OnEnter()
    warn("CarouselAction:OnEnter")
    M.super.OnEnter(self)
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
    _APP.AI.carousel = false
    warn("CarouselAction:OnLeave", msg)
end

function M:GetStartTime()
    return self.startTime
end

return M
