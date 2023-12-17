---@class Game.AnimationTool.AnimationLoader
local M = class()
local SM = require("ServiceManager")
local TickService = SM.GetTickService()
local AssetService = CS.Extend.Asset.AssetService
local AutoRecycleType = typeof(CS.Extend.Asset.AutoRecycle)

local AnimationOverrides = {
	{"SingleAction"},
	{"ActionStart", "ActionLoop", "ActionEnd", "ActionStart2", "ActionLoop2", "ActionEnd2"},
	{"SingleLoop"},
}

function M:ctor(owner)
	self.owner = owner
	self.loadings = {}
	self.loaded = {}
	self.exitTime = 999
	self.tickTime = 0
	self.loopAnimationTrackIndex = 1
end

function M:GetConfig()
	return self.config
end

function M:LoadConfig(configKey)
	local ConfigService = SM.GetConfigService()
	self.config = assert(ConfigService.GetConfigRow("NPCAnimation", configKey), configKey)
end

function M:LoadAndPlayAnimation(duration)
	self:Clear()

	if self.config.animationLayer == 2 then
		self.SINGLE_ACTION = SINGLE_ACTION_UPPER
		self.START_LOOP_ACTION = START_LOOP_ACTION_UPPER
		self.LOOP_EXIT = LOOP_EXIT_UPPER
	else
		self.SINGLE_ACTION = SINGLE_ACTION
		self.START_LOOP_ACTION = _G["START_LOOP_ACTION_" .. self.loopAnimationTrackIndex]
		self.LOOP_EXIT = _G["LOOP_EXIT_" ..  self.loopAnimationTrackIndex]
	end

	self.duration = duration
	self.owner:GetAnimator():ResetTrigger(self.LOOP_EXIT)
	local loader = _APP:GetCurrentState():GetStateLoader()
	local overrides = AnimationOverrides[self.config.animationType]
	self.loadingStartTime = TickService.totalTime
	for index, animationAssetPath in ipairs(self.config.animations) do
		local animationIndex = index
		local fullPath = string.format("Assets/Res/Avatar/Animation/%s", animationAssetPath)
		self.loadings[index] = loader:LoadAnimationClipAsync(fullPath, function(clipRef)
			local override
			if self.config.animationLayer == 2 then
				override = overrides[animationIndex] .. "_Upper"
			else
				if self.config.animationType ~= 2 then
					override = overrides[animationIndex]
				else
					override = overrides[self.loopAnimationTrackIndex == 1 and animationIndex or animationIndex + 3]
				end
			end
			self.loadings[animationIndex] = nil
			self.owner:GetAnimator():ChangeClip(override, clipRef:GetAnimationClip())
			self.loaded[animationIndex] = clipRef
			self:StartAnimation()
		end)
	end

	if self.config.emotion ~= "0" then
		local emotionPath = string.format("Assets/Res/Prefabs/Avatar/Emotion/%s.prefab", self.config.emotion)
		self.loadings["emotion"] = loader:LoadGameObjectAsync(emotionPath, function(go)
			self.loadings["emotion"] = nil
			go.transform:SetParent(self.owner:GetTransform(), false)
			self.effectGO = go
			self:StartAnimation()
		end, true)
	end

	if self.config.widget ~= "0" then
		local widgetPath = string.format("Assets/Res/Prefabs/%s.prefab", self.config.widget)
		self.loadings["widget"] = loader:LoadGameObjectAsync(widgetPath, function(go)
			self.loadings["widget"] = nil
			local bone = self.owner:GetSlotProvider():GetSlot(self.config.slotName)
			go.transform:SetParent(bone, false)
			self.widgetGO = go
			self.widgetGO:SetActive(false)
			self:StartAnimation()
		end, true)
	end
	if self.config.sound ~= "0" then
		local switch = self.owner.config.gender == 1 and WwiseInfo.Switches.Npc_Gender.Male or WwiseInfo.Switches.Npc_Gender.Female
		--AudioUtilities.SetSwitch(WwiseInfo.SwitchGroups.Npc_Gender, switch, self.owner.go)
		--self.soundEventId = AudioUtilities.PostEvent(self.config.sound, self.owner.go)
	end
end

function M:LoadOverrideAnimation(path, override, callback)
	if string.isNullOrEmpty(path) then
		self.owner:GetAnimator():ChangeClip(override,nil)
		return
	end
	local fullPath = string.format("Assets/Res/Avatar/Animation/%s", path)
	local loader = _APP:GetCurrentState():GetStateLoader()
	loader:LoadAnimationClipAsync(fullPath, function(clipRef)
		self.owner:GetAnimator():ChangeClip(override, clipRef:GetAnimationClip())
		if callback then
			callback(override)
		end
	end)
	
	self.owner:GetAnimator():GetComponent("Animator"):Update(0)
end

function M:StartAnimation()
	if not table.empty(self.loadings) then
		return
	end
	---@type base.EventDispatcher
	local eventDispatcher = self.owner:GetEventDispatcher()
	eventDispatcher:DispatchEvent("AnimationStart")
	if self.config.animationType == 2 and self.duration then
		---@type CS.UnityEngine.AnimationClip
		local clip = self.loaded[3]:GetAnimationClip()
		self.exitTime = self.duration - clip.length - (TickService.totalTime - self.loadingStartTime)
	end
	if self.config.animationType == 1 then
		self.owner:GetAnimator():SetTrigger(self.SINGLE_ACTION)
	elseif self.config.animationType == 2 then
		self.owner:GetAnimator():SetTrigger(self.START_LOOP_ACTION)
		self.loopAnimationTrackIndex = self.loopAnimationTrackIndex % 2 + 1
	elseif self.config.animationType == 3 then
		self.owner:GetAnimator():SetTrigger(SINGLE_LOOP)
	end
end

function M:StopAnimation()
	if not self.config then return end
	if self.config.animationType == 2 then
		self.owner:GetAnimator():SetTrigger(self.LOOP_EXIT)
	elseif self.config.animationType == 3 then
		self.owner:GetAnimator():SetTrigger(SINGLE_LOOP_EXIT)
	end
end

function M:GetAnimationClip(index)
	local clip = self.loaded[index]:GetAnimationClip()
	return clip
end

function M:GetExitTime()
	return self.exitTime
end

function M:Tick()
	self.tickTime = self.tickTime + TickService.deltaTime
	if self.config.animationType == 2 and self.tickTime > self.exitTime and not self.triggerExit then
		self.triggerExit = true
		self.owner:GetAnimator():SetTrigger(self.LOOP_EXIT)
	end
end

function M:GetTriggerExit()
	return self.triggerExit == true
end

function M:GetWidgetGO()
	return self.widgetGO
end

function M:Clear()
	self.triggerExit = nil
	self.exitTime = 999
	self.tickTime = 0
	for _, loadingContext in pairs(self.loadings) do
		loadingContext.cancel = true
	end

	for _, clipRef in pairs(self.loaded) do
		clipRef:Dispose()
	end

	if self.effectGO then
		local autoRecycle = self.effectGO:GetComponent(AutoRecycleType)
		if autoRecycle then
			autoRecycle:Stop()
		else
			AssetService.Recycle(self.effectGO)
		end
		self.effectGO = nil
	end
	if self.widgetGO then
		AssetService.Recycle(self.widgetGO)
		self.widgetGO = nil
	end

	if self.soundEventId then
		--AudioUtilities.StopPlayingID(self.soundEventId)
		self.soundEventId = nil
	end

	self.loadings = {}
	self.loaded = {}
end

return M