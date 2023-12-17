
---@class Game.Network.WebRequest
local M = {}
local UnityWebRequest = CS.UnityEngine.Networking.UnityWebRequest
local UploadHandlerRaw = CS.UnityEngine.Networking.UploadHandlerRaw
local DownloadHandlerBuffer = CS.UnityEngine.Networking.DownloadHandlerBuffer

local cjson = require("cjson")
local localStoredCookies = {}
local SM = require("ServiceManager")
local ConfigService = SM.GetConfigService()
ConfigService.GetConfig("WebRequest")
local WWWForm = CS.UnityEngine.WWWForm

function M._BuildQueryString(urlKey, query)
	local row = assert(ConfigService.GetConfigRow("WebRequest", urlKey), urlKey)
	local url = row.url

	if not query then
		return url
	end
	local queryList = {}
	for key, value in pairs(query) do
		table.insert(queryList, key .. "=" .. value)
	end
	query = table.concat(queryList, "&")
	return url .. "?" .. query
end

function M._BuildFormData(filePath, data)
	local f = io.open(filePath, "rb")
	local formData = WWWForm()
	for key, value in pairs(data) do
		formData:AddField(key, value)
	end
	formData:AddBinaryData("file", f:read("*all"),'recorder.wav', "application/octet-stream")
	f:close()
	return formData
end

function M._SetupHeaderRetAccount(request, header)
	if not header then
		return
	end
	for key, value in pairs(header) do
		request:SetRequestHeader(key, value)
	end
end

function M.Get(urlKey, query, header, callback)
	local request = UnityWebRequest.Get(M._BuildQueryString(urlKey, query))
	return M.DoRequest(request, callback, header)
end

function M.GetById(urlKey,roleId, token, callback)
	local row = assert(ConfigService.GetConfigRow("WebRequest", urlKey), urlKey)
	local url = row.url..roleId
	warn("Url is ",url)
	local request = UnityWebRequest.Get(url)
	request:SetRequestHeader("Authorization", "Bearer "..token)
	return M.DoRequest(request, callback, header)
end

function M.PutJson(urlKey, roleId, token, data, callback)
	local row = assert(ConfigService.GetConfigRow("WebRequest", urlKey), urlKey)
	local url = row.url..roleId
	local request = UnityWebRequest(url, "PUT")
	request:SetRequestHeader("Authorization", "Bearer "..token)
	local json = cjson.encode(data)
	warn("Putjson is ",json)
	local uploadHandler = UploadHandlerRaw(json)
	uploadHandler.contentType = "application/json;charset=utf-8"
	request.uploadHandler = uploadHandler
	request.downloadHandler = DownloadHandlerBuffer()
	return M.DoRequest(request, callback, header)
end

function M.PostJson(urlKey,  header, data, callback,nolog)
	local row = assert(ConfigService.GetConfigRow("WebRequest", urlKey), urlKey)
	local url = _APP.urlHead..row.url
	if not nolog then
		print("PostJson is ",url)

		if data then
			print("Post data is ",table.dump_r(data))
		end
		if header then
			print("Post header is ",table.dump_r(header))
		end
	end
	local request = UnityWebRequest(url, "POST")
	local uploadHandler = UploadHandlerRaw(cjson.encode(data))
	uploadHandler.contentType = "application/json;charset=utf-8"
	request.uploadHandler = uploadHandler
	request.downloadHandler = DownloadHandlerBuffer()
	return M.DoRequest(request, callback,header)
end

function M.PostLoginJson(urlHead,urlKey,  header, data, callback)
	local row = assert(ConfigService.GetConfigRow("WebRequest", urlKey), urlKey)
	local url = urlHead..row.url
	warn("PostLoginJson is ",url)
	local request = UnityWebRequest(url, "POST")
	local uploadHandler = UploadHandlerRaw(cjson.encode(data))
	uploadHandler.contentType = "application/json;charset=utf-8"
	request.uploadHandler = uploadHandler
	request.downloadHandler = DownloadHandlerBuffer()
	return M.DoRequest(request, callback,header)
end

function M.PostFile(urlKey, query, header, filePath, callback)
	local url = M._BuildQueryString(urlKey, query)
	warn("PostFile is ",url)
	local request = UnityWebRequest(url, "POST")
	request.method = "POST"
	local f = io.open(filePath, "rb")
	local uploadHandler = UploadHandlerRaw(f:read("*all"))
	f:close()
	request.uploadHandler = uploadHandler
	request.downloadHandler = DownloadHandlerBuffer()
	return M.DoRequest(request, callback, header)
end


function M.PostFileFrom(urlKey, data, header, filePath, callback)
	local url =_APP.urlHead..M._BuildQueryString(urlKey, nil)
	warn("PostFile is ",url)
	local formData = M._BuildFormData(filePath,data)
	local request = UnityWebRequest.Post(url, formData)
	return M.DoRequest(request, callback, header)
end

function M.PostFileBytes(urlKey, query, header, bytes, callback)
	local request = UnityWebRequest(M._BuildQueryString(urlKey, query), "POST")
	request.method = "POST"
	local uploadHandler = UploadHandlerRaw(bytes)
	request.uploadHandler = uploadHandler
	request.downloadHandler = DownloadHandlerBuffer()
	return M.DoRequest(request, callback, header)
end

local cookieFilter = {"expires", "max-age", "path", "httponly", "secure", "domain", "samesite"}
---@param request UnityEngine.Networking.UnityWebRequest
function M.DoRequest(request, callback, header)
	request.timeout = 10
	--if string.startWith(request.url, "https") then
	--	request.certificateHandler = WebRequestCertificate()
	--end
	M._SetupHeaderRetAccount(request, header)
	local operation = request:SendWebRequest()
	if not callback then
		return
	end
	local cancelContext = {cancel = false}
	operation:completed("+", function()
		if cancelContext.cancel then
			return
		end

		if cancelContext.go and not CS.Extend.LuaUtil.UnityExtension4XLua.CheckObjectDestroyed(cancelContext.go) then
			return
		end

		if not string.isNullOrEmpty(request.error) then
			warn(request.url)
			warn(request.error)
			return
		end

		--local cookieToCache = request:GetResponseHeader("set-cookie")
		--if cookieToCache then
		--	local cookies = string.split(cookieToCache, ";")
		--	local filteredCookies = {}
		--	for _, cookie in ipairs(cookies) do
		--		local index = table.index_of_predict(cookieFilter, function(filter)
		--			return string.startWith(cookie, filter)
		--		end)
		--		if index == -1 then
		--			table.insert(filteredCookies, cookie)
		--		end
		--	end
		--	if #filteredCookies > 0 then
		--		local cookie = table.concat(filteredCookies, ";")
		--		localStoredCookies[userId] = cookie
		--	end
		--end

		local success, message = xpcall(callback, debug.traceback, request.downloadHandler.text)
		if not success then
			error(message)
		end
		request:Dispose()
	end)
	return cancelContext
end

return M