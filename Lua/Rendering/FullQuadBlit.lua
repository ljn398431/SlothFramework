local Graphics = CS.UnityEngine.Graphics
local RenderTexture = CS.UnityEngine.RenderTexture
local Destroy = CS.UnityEngine.Object.Destroy

local M = {}
local combineMaterialRef
---@type CS.UnityEngine.Material
local combineMaterial

local xBRZScaler
local xBRZScalerConfig
local scaleSize

local _TopLeftTexShaderPropertyID = CS.UnityEngine.Shader.PropertyToID("_TopLeftTex")
local _TopRightTexShaderPropertyID = CS.UnityEngine.Shader.PropertyToID("_TopRightTex")
local _BottomLeftTexShaderPropertyID = CS.UnityEngine.Shader.PropertyToID("_BottomLeftTex")
local _BottomRightTexShaderPropertyID = CS.UnityEngine.Shader.PropertyToID("_BottomRightTex")
local _TopTexSizeShaderPropertyID = CS.UnityEngine.Shader.PropertyToID("_TopTexSize")

function M.Init()
	combineMaterialRef = CS.Extend.Asset.AssetService.Get():LoadMaterial("Assets/Shader/Fullscreen/FourQuadrantsTextures.mat")
	combineMaterial = combineMaterialRef:GetMaterial()

	if _VersionCompare(CS.UnityEngine.Application.version, "2.5.0") then
		xBRZScaler = CS.xBRZNet.xBRZScaler()
		xBRZScalerConfig = CS.xBRZNet.ScalerCfg()
		xBRZScalerConfig.EqualColorTolerance = 60
		xBRZScalerConfig.DominantDirectionThreshold = 2
	end
end

function M.Upscale(source)
end

function M._FilterTextureSize(texture)
	if not texture then
		return
	end
	scaleSize = texture.width * 4
	return texture
end

function M._xBRZUpScale(texture)
	if not texture then
		return
	end
	scaleSize = texture.width * 4
	return xBRZScaler:ScaleImage(texture, 4, xBRZScalerConfig)
end

function M._ReleaseTempTexture(texture)
	if not texture then
		return
	end
	Destroy(texture)
end

local PointFilter = CS.UnityEngine.FilterMode.Point
---@param dest CS.UnityEngine.RenderTexture
function M.Combine4TextureAndUpscale(bottomLeft, bottomRight, topLeft, topRight, dest, topHeight)
	topHeight = topHeight or 32
	if xBRZScaler then
		bottomLeft = M._xBRZUpScale(bottomLeft)
		bottomRight = M._xBRZUpScale(bottomRight)
		topLeft = M._xBRZUpScale(topLeft)
		topRight = M._xBRZUpScale(topRight)
	else
		bottomLeft = M._FilterTextureSize(bottomLeft)
		bottomRight = M._FilterTextureSize(bottomRight)
		topLeft = M._FilterTextureSize(topLeft)
		topRight = M._FilterTextureSize(topRight)
	end
	combineMaterial:SetFloat(_TopTexSizeShaderPropertyID, topHeight / 64)
	combineMaterial:SetTexture(_BottomLeftTexShaderPropertyID, bottomLeft)
	combineMaterial:SetTexture(_BottomRightTexShaderPropertyID, bottomRight)
	combineMaterial:SetTexture(_TopLeftTexShaderPropertyID, topLeft)
	combineMaterial:SetTexture(_TopRightTexShaderPropertyID, topRight)

	local activeRT = RenderTexture.active
	local combineSize = scaleSize * 2
	local combinedRT = RenderTexture.GetTemporary(combineSize, combineSize)
	combinedRT.filterMode = PointFilter
	Graphics.Blit(nil, combinedRT, combineMaterial)
	if xBRZScaler then
		M._ReleaseTempTexture(bottomLeft)
		M._ReleaseTempTexture(bottomRight)
		M._ReleaseTempTexture(topLeft)
		M._ReleaseTempTexture(topRight)
	end
	local upscaleSource = combinedRT
	combineSize = combineSize << 1
	while combineSize < dest.width do
		upscaleSource.filterMode = PointFilter
		combinedRT = RenderTexture.GetTemporary(combineSize, combineSize)
		Graphics.Blit(upscaleSource, combinedRT)
		RenderTexture.ReleaseTemporary(upscaleSource)
		upscaleSource = combinedRT
	end
	
	Graphics.Blit(upscaleSource, dest)
	RenderTexture.ReleaseTemporary(upscaleSource)
	RenderTexture.active = activeRT
end

local inUsedRenderTextures = {}
local globalId = 1

function M.CreateRenderTexture(size, name, depth)
	globalId = globalId + 1
	local rt = CS.UnityEngine.RenderTexture(size, size, depth or 0)
	rt.name = name
	inUsedRenderTextures[globalId] = rt
	return globalId
end

function M.ReleaseRenderTexture(id)
	local rt = inUsedRenderTextures[id]
	inUsedRenderTextures[id] = nil
	if rt then
		CS.UnityEngine.Object.Destroy(rt)
	end
end

function M.GetRenderTexture(id)
	return inUsedRenderTextures[id]
end

function M.clear()
	if table.empty(inUsedRenderTextures) then
		return
	end
	
	error("Render texture leak", table.count(inUsedRenderTextures))
	for id, rt in pairs(inUsedRenderTextures) do
		error("Name:", rt.name)
		M.ReleaseRenderTexture(id)
	end
end

return M