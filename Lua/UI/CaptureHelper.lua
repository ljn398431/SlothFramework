---@class UI.CaptureHelper
local M = {}

local RenderTexture = CS.UnityEngine.RenderTexture
local RenderTextureFormat = CS.UnityEngine.RenderTextureFormat
local TextureFormat = CS.UnityEngine.TextureFormat
local Rect = CS.UnityEngine.Rect
local Texture2D = CS.UnityEngine.Texture2D

---@param width number
---@param height number
---@param cameraCapture CS.UnityEngine.Camera
---@param needRawData boolean|nil if true will return Texture2D
function M.CaptureTexture(width, height, cameraCapture, needRawData)
	local rt = RenderTexture(width, height, 24, RenderTextureFormat.ARGB32);
	rt.antiAliasing = 1;
	rt.autoGenerateMips = false;
	rt:Create();
	rt.name = "icon";
	local originRT = cameraCapture.targetTexture
	local result = rt
	cameraCapture.targetTexture = rt;
	cameraCapture:Render()
	if needRawData then
		result = M.ConvertRenderTexture2Texture2D(result)
	end
	cameraCapture.targetTexture = originRT
	return result
end

---@param rt CS.UnityEngine.RenderTexture
---@param keepOriginalData boolean|nil if false will release rt
---@return CS.UnityEngine.Texture2D result
function M.ConvertRenderTexture2Texture2D(rt, keepOriginalData)
	local currentRT = RenderTexture.active;
	local result = Texture2D(rt.width, rt.height, TextureFormat.RGBA32, false);
	RenderTexture.active = rt;
	result:ReadPixels(Rect(0, 0, rt.width, rt.height), 0, 0, false);
	result:Apply();
	RenderTexture.active = currentRT;
	if not keepOriginalData then
		rt:Release()
	end
	return result
end

---@param rt CS.UnityEngine.RenderTexture
---@param keepOriginalData boolean if false will release rt
---@return Array<byte> result
function M.GetRenderTexturePixelsBytes(rt, keepOriginalData)
	local texture2d = M.ConvertRenderTexture2Texture2D(rt, keepOriginalData)
	local result = texture2d:EncodeToPNG()
	CS.UnityEngine.Object.Destroy(texture2d)
	return result
end

local AlphaShaderPropId = CS.UnityEngine.Shader.PropertyToID("_Alpha")
local AlbedoShaderPropId = CS.UnityEngine.Shader.PropertyToID("_Albedo")

---@param width number
---@param height number
---@param captureCamera CS.UnityEngine.Camera
---@param targetMeshRenderer CS.UnityEngine.Renderer Renderer that need to handle alpha
---@param texture  CS.UnityEngine.Texture input to renderer material
function M.CaptureTextureByRenderer(width, height, captureCamera, targetMeshRenderer, texture)
	targetMeshRenderer.sharedMaterial:SetFloat(AlphaShaderPropId, 1)
	targetMeshRenderer.sharedMaterial:SetTexture(AlbedoShaderPropId, texture)
	return M.CaptureTexture(width, height, captureCamera, true)
end

return M