local LuaBindingBase = require("base.LuaBindingBase")
local Vector3 = CS.UnityEngine.Vector3

---@class Game.IK.LookAt : LuaBinding
---@field animator CS.UnityEngine.Animator
local M = class(LuaBindingBase)

function M:awake()
	self.transform = self.__CSBinding.transform
	self.targetWeight = 0
	self.currentWeight = 0
end

function M:SetActive(active)
	self.active = active
	if active then
		local ikBinding = self.__CSBinding:GetComponent("LuaAnimatorIKBinding")
		ikBinding:AssignLuaBinding(self.__CSBinding)
	end
end

function M:SetLookTargetPosition(position, focusYOffset)
	self.lookAtPosition = Vector3(position.x, position.y + focusYOffset or 0, position.z)
end

function M:animator_ik()
	local ignorePosition = false
	if not self.active then
		self.targetWeight = 0
		ignorePosition = true
		return
	end
	local position = self.transform.position
	local lookDirection = Vector3(self.lookAtPosition.x - position.x, 0, self.lookAtPosition.z - position.z)
	if Vector3.Angle(self.transform.forward, lookDirection) > 60 then
		self.targetWeight = 0
		ignorePosition = true
		return
	end

	self.targetWeight = 1
	if not ignorePosition then
		self.animator:SetLookAtPosition(self.lookAtPosition)
	end
	if self.currentWeight ~= self.targetWeight then
		self.currentWeight = math.lerp(self.currentWeight, self.targetWeight, 0.0166666)
	end

	self.animator:SetLookAtWeight(self.currentWeight)
end

return M