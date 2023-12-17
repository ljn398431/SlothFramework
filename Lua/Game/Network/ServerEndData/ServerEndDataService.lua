local LuaSocketClient = require("Game.Network.LuaSocketClient")
local SM = require("ServiceManager")
local Account = require("Game.Network.ServerEndData.Account")
local Scene = require("Game.Network.ServerEndData.Scene")
local Player = require("Game.Network.ServerEndData.Player")
local Tracker = require("Game.Network.ServerEndData.TrackerNew")
local Iot = require("Game.Network.ServerEndData.Iot")
local cjson = require("cjson")
--local Tip = require("UI.Panels.Tip")

---@class Game.Network.ServerEndData.ServerEndDataService
local M = {}
---@type Game.Network.LuaSocketClient
local socketClient
local wsHead = "ws://clouds1.prisoi.com:7087"
function M.Init()
	Player.Init()
	Account.Init()
	Tracker.Init()
	Scene.Init()
	Iot.Init()
end

function M._NewClient()
	assert(not socketClient)
	socketClient = LuaSocketClient.new()
end

function M.Tick()
	if not socketClient then
		return
	end
	socketClient:Tick()
end

function M.InitTestSocket()
	local serverAddress = wsHead .. "/digitalcharacter/websocket/message"
	M._NewClient()
	socketClient:RegisterServerRequest("SMessage", M.OnServerMessage)
	socketClient:ConnectAsync(serverAddress)
end

function M.InitSocket(token)
	local serverAddress = wsHead .. "/digitalcharacter/websocket/user/" .. token
	M._NewClient()
	--M.UpdateWebSocketHeader()
	socketClient:RegisterServerRequest("SMessage", M.OnServerMessage)
	socketClient:ConnectAsync(serverAddress)
end

function M.SocketReconnect(token)
	local serverAddress = wsHead .. "/digitalcharacter/websocket/user/" .. token
	socketClient:ConnectAsync(serverAddress)
end

function M.Login(head, callback)
	local WebRequest = require("Game.Network.WebRequest")
	WebRequest.PostLoginJson(head, "login", nil, {
		characterCode = _ServerEndData.GetAccountData().characterCode,
		password = "123456" }, function(data)
		data = cjson.decode(data)
		callback(data)
	end)
end

function M.EnterArea(areaCode)
	local WebRequest = require("Game.Network.WebRequest")
	if(areaCode ~=  _ServerEndData.GetAccountData().areaCode) then
		_ServerEndData.GetAccountData().areaCode = areaCode
		WebRequest.PostJson( "enterArea", {token = M.GetAccountData().token}, {
			characterCode = _ServerEndData.GetAccountData().characterCode,
			areaCode = areaCode }, function(data)
			warn("enterArea", data)
			data = cjson.decode(data)
			local PlayerService = require("Player.PlayerService")
			PlayerService.SPlayerState(data.data)
			for i, v in ipairs(data.data) do
				warn("enterArea player",i, table.dump_r(v))
			end
		end)
	end
	WebRequest.PostJson("guideCharacterAreaInfo", { token = M.GetAccountData().token }, {
		characterCode = _ServerEndData.GetAccountData().characterCode,
		areaCode = areaCode }, function(data)
		warn("guideCharacterAreaInfo", data)
		data = cjson.decode(data)
		if data.guideCharacterInfo then
			M._UpdateGuideCharacterInfo(data)
		end
	end)
	Iot.Init()
	WebRequest.PostJson("areaIoTInfo",{token = M.GetAccountData().token},{
		characterCode = M.GetAccountData().characterCode,
		areaCode = areaCode },function(package)
		warn("areaIoTInfo",package)
		local data = cjson.decode(package)
		if data.code == 0 then
			for _,v in ipairs(data.data) do
				Iot.ParseFromServerData(v)
			end
		end
	end)
	local playerData = Player.GetPlayerById(_ServerEndData.GetAccountData().characterCode)
	warn("broadcasting playerData", table.dump_r(playerData))
	if playerData == nil then
		return
	end
	local requestData = {
		type = "broadcasting",
		id = playerData.id,
		userName = _ServerEndData.GetAccountData().name,
		characterCode = playerData.id,
		mode = "EnterArea",
		gender = playerData.gender,
		wearing = playerData.wearing,
		areaCode = areaCode
	}
	warn("broadcasting EnterArea", table.dump_r(requestData))
	_ServerEndData.GetSocket():SendData(requestData)
end

function M._UpdateGuideCharacterInfo(data)
	local account = _ServerEndData.GetAccountData()
	account.bgUrl =  data.guideCharacterInfo.backgroundImage
	account.alpha = data.guideCharacterInfo.transparency/100
	_APP.chatStytle = data.guideCharacterInfo.interfaceStyle == "ChatPanel" and 1 or 2
	local tracker = _ServerEndData.GetTracker()
	tracker.content = data.guideCharacterInfo.broadcastText
	tracker.fontColor = data.guideCharacterInfo.broadcastTextColor
end

function M.UpdateWebSocketHeader()
	if not socketClient then
		return
	end
	--socketClient:SetOrUpdateHeader("Extension-Signal", {userId = M.GetAccountData().userId, accessKey = M.GetAccountData().accessKey})
end

function M.OnServerMessage(p)
	local meta = p.Meta
	if p.MessageType == "Toast" then
		_ToastManager.ShowTip(meta.Icon, meta.Content, meta.Duration)
	elseif p.MessageType == "Tip" then
		Tip.ShowTip(meta.Title, meta.Content, meta.Duration)
	end
end

---@return Game.Network.LuaSocketClient
function M.GetSocket()
	return socketClient
end

function M.GetAccountData()
	return Account.GetData()
end

function M.GetPlayerData()
	return Player.GetData()
end

function M.GetTracker()
	return Tracker.GetData()
end

function M.GetSceneData()
	return Scene.GetData()
end

function M.GetIotData()
	return Iot.GetData()
end

local serverTimeSyncTime
local serverTime
function M.GetServerTime()
	serverTimeSyncTime = SM.GetTickService().realtimeSinceStartup
	
	--local diff = SM.GetTickService().realtimeSinceStartup - serverTimeSyncTime
	serverTime = CS.System.DateTime.UtcNow / 1000 + delayInSeconds
	return serverTime
end

function M.GetServerTimeMilli()
	serverTime = CS.System.DateTime.UtcNow.Ticks/ CS.System.TimeSpan.TicksPerMillisecond
	--local diff = SM.GetTickService().realtimeSinceStartup - serverTimeSyncTime
	return serverTime
end

function M.SetServerTime(utcTimeInMilliSeconds, delayInSeconds)
	serverTimeSyncTime = SM.GetTickService().realtimeSinceStartup
	serverTime = utcTimeInMilliSeconds / 1000 + delayInSeconds
end

function M.Close()
	socketClient:Close()
	socketClient = nil
end

function M.clear()
end

_ServerEndData = M
return M