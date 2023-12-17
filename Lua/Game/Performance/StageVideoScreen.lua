local LuaBindingBase = require("base.LuaBindingBase")

---@class Game.Performance.StageVideoScreen : LuaBinding
---@field videoPlayer CS.UnityEngine.GameObject
---@field screenMaterial CS.UnityEngine.Material
---@field staticScreenTexture CS.UnityEngine.Texture
local M = class(LuaBindingBase)

local MainPropertyId = CS.UnityEngine.Shader.PropertyToID("_Main")

function M:start()
	if Global_Quality == "Low" then
		self.videoPlayer:SetActive(false)
		self.screenMaterial:SetTexture(MainPropertyId, self.staticScreenTexture)
	end
end

return M