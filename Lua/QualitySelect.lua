local platform = CS.UnityEngine.Application.platform
Global_Quality = "Middle"

local function MaliGPU_QualitySelector(deviceName)
	local deviceNumber = tonumber(string.match(deviceName, "%d+"))
	if deviceNumber > 100 then
		if deviceNumber < 400 then
			return "Low"
		elseif deviceNumber < 700 then
			return "Middle"
		else
			return "Middle"
		end
	else
		if deviceNumber < 60 then
			return "Low"
		elseif deviceNumber <= 76 then
			return "Middle"
		else
			return "Middle"
		end
	end
	return "Low"
end

local function AdrenoGPU_QualitySelector(deviceName)
	local versionCode = tonumber(string.match(deviceName, "%d+"))
	if versionCode then
		if versionCode < 500 then
			return "Low"
		end

		versionCode = versionCode % 100
		if versionCode < 10 then
			return "Low"
		elseif versionCode <= 20 then
			return "Middle"
		else
			return "Middle"
		end
	end
	return "Low"
end

local function Android_QualitySelector(processorFrequency, graphicsDeviceName)
	local first, last = string.find(graphicsDeviceName, "Immortalis")
	if first then
		return "Middle"
	end

	first, last = string.find(graphicsDeviceName, "Mali")
	if first then
		return MaliGPU_QualitySelector(string.sub(graphicsDeviceName, last + 1))
	end

	first, last = string.find(graphicsDeviceName, "Adreno")
	if first then
		return AdrenoGPU_QualitySelector(string.sub(graphicsDeviceName, last + 1))
	end
	return "Low"
end

local function iOS_QualitySelector(processorFrequency, graphicsDeviceName)
	local versionCode = tonumber(string.match(graphicsDeviceName, "%d+"))
	if versionCode <= 12 then
		return "Middle"
	end
	return "Middle"
end

local function Win_QualitySelector(processorFrequency, graphicsDeviceName)
	warn("Win_QualitySelector", processorFrequency, graphicsDeviceName)
	return "Middle"
end

function Global_QualitySelector(...)
	if CS.UnityEngine.Application.isMobilePlatform and not CS.UnityEngine.SystemInfo.SupportsTextureFormat(CS.UnityEngine.TextureFormat.ASTC_6x6) then
		error("ASTC Not Support.")
		Global_Quality = "Low"
		return Global_Quality
	end
	local selector
	if platform == CS.UnityEngine.RuntimePlatform.Android then
		selector = Android_QualitySelector
	else if platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer then
		selector = Win_QualitySelector
	else
		selector = iOS_QualitySelector
	end
	end
	local ok, quality = xpcall(selector, debug.traceback, ...)
	if not ok then
		error("Quality select fail.", ...)
		Global_Quality = "Low"
	else
		Global_Quality = quality == "High" and "Middle" or quality
	end
	warn("Graphics quality select : ", Global_Quality)
	return Global_Quality
end
