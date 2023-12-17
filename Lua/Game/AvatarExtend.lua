local AvatarEquipment = require("Game.Equipment.AvatarEquipment")
local AnimationLoader = require("Game.AnimationTool.AnimationLoader")
--local PinchFace = require("Game.Player.PinchFace")
local EventDispatcher = require("base.EventDispatcher")
local AssetService = CS.Extend.Asset.AssetService

return function(unitModule)
	---@class Game.AvatarExtend
	local M = unitModule

	function M:SetupEquipment(appearance)
		self.avatarEquipment = AvatarEquipment.new(appearance, self)
	end
	
	---@param go CS.UnityEngine.GameObject
	function M:SetupAvatar(go)
		self.transform = go.transform
		self.animator = self.transform:GetComponent("AnimatorParameterLuaCommunicator")
		self.go = go

		self.animationLoader = AnimationLoader.new(self)
		--self.slotProvider = go:GetComponent("SlotProvider")
		self.eventDispatcher = EventDispatcher.new()
	end

	---@param loader Game.AnimationTool.AnimationLoader
	function M:SetOverrideAnimations(loader,config,isLoad)
		for i = 1, 5 do
			loader:LoadOverrideAnimation(isLoad and config.animations[i] or nil, config.overrides[i], function(_)
			end)
		end
	end
	
	---@return CS.DigitalHuman.Util.SlotProvider
	function M:GetSlotProvider()
		return self.slotProvider
	end
	
	function M:GetEventDispatcher()
		return self.eventDispatcher
	end

	--随机下一次待机动作
	function M:SetAvatarIdle()
		local index = math.random(1, 3)
		self.animator:SetInteger(IDLE_TYPE_PARAM, index)
	end

	---@return CS.UnityEngine.Transform
	function M:GetTransform()
		return self.transform
	end

	function M:SetRotation(rotation)
		self.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, rotation, 0)
	end

	---@return CS.Extend.LuaUtil.AnimatorParameterLuaCommunicator
	function M:GetAnimator()
		return self.animator
	end

	function M:GetGameObject()
		return self.go
	end

	function M:GetAvatarEquipment()
		return self.avatarEquipment
	end

	function M:AddEmotion(emotionType)
		self:RemoveEmotion()

		local path = string.format("Assets/Res/Prefabs/Avatar/Emotion/Emotion_%s.prefab", emotionType)	
		-- warn("PlayEmotion path = ", path)
		local loadHandle = AssetService.Get():LoadGameObjectAsync(path)
		loadHandle:OnComplete("+", function()
			local result = loadHandle.Result
			local instantiateAsyncContext = result:InstantiateAsync(self.transform, false)
			instantiateAsyncContext:Callback("+", function(go)
				self.emotionGo = go
				result:Dispose()
			end)
		end )
	end

	function M:RemoveEmotion()
		if self.emotionGo then
			AssetService.Recycle(self.emotionGo)
			self.emotionGo = nil
		end
	end

	---@param other Game.Equipment.AvatarEquipment
	---@param faceData string
	function M:EqualsEquipment(faceData, other)
		if self.avatarEquipment == other then
			return true
		end
		if self.avatarEquipment == nil then
			return false
		end
		return self.avatarEquipment:Equals(other) and faceData == self.faceData
	end

	---@return Game.AnimationTool.AnimationLoader
	function M:GetAnimationLoader()
		return self.animationLoader
	end

	function M:GetAvatarRenderRoot()
		return self.avatarRenderRoot
	end

	function M:Destroy()
		self.transform = nil
		self.avatarRenderRoot = nil
		self.animator = nil
		if self.avatarEquipment then
			self.avatarEquipment:Destroy()
			self.avatarEquipment = nil
		end
		AssetService.Recycle(self.go)
		self.go = nil

		self:RemoveEmotion()
	end
end