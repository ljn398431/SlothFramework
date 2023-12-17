---@class Game.Network.LuaSocketClient
local M = class()
local SocketClient = CS.DigitalHuman.Network.SocketClient
local cjson = require("cjson")
local base64 = require("base64")
local SM = require("ServiceManager")
local TickService = SM.GetTickService()
local SEDService = SM.GetServerEndDataService()
local MsgBox = require("UI.Panels.MessageBox")
local SocketStatus = CS.DigitalHuman.Network.SocketClient.SocketStatus

function M:ctor()
    self.serverRequests = {}
    self.client = SocketClient(self)
    TickService = SM.GetTickService()
    self.lastHeartBeatTime = 0
    self.lastConnectedTime = TickService.realtimeSinceStartup
    self.connectingTime = 0
    self.reconnect = false
    self.showLoading = false
    self:RegisterServerRequest("SHeartBeat", self._SHeartBeat, self)
    self:RegisterServerRequest("SReconnect", self.Reconnect, self)
end

function M:SetOrUpdateHeader(header, data)
    local json = cjson.encode(data)
    self.client:SetOrUpdateHeader(header, base64.enc(json))
end

function M:RegisterServerRequest(type, callback, target)
    assert(not self.serverRequests[type], type)
    self.serverRequests[type] = {
        callback = callback,
        target = target
    }
end

function M:UnregisterServerRequest(type)
    self.serverRequests[type] = nil
end

---@param status CS.DigitalHuman.Network.SocketClient.SocketStatus
function M:OnStatusChanged(status)
    print("Status", status)
    self.status = status
    if self.status == CS.DigitalHuman.Network.SocketClient.SocketStatus.Connected then
        self.reconnect = false
        if self.showLoading then
            SM.GetUIService().Hide("NetLoading")
        end
    end

    local currentState = _APP:GetCurrentState()
    if not currentState.SocketStatusChanged then
        return
    end
    currentState:SocketStatusChanged(status)
end

function M:GetStatus()
    return self.status
end

function M:ConnectAsync(address)
    self.lastHeartBeatTime = TickService.realtimeSinceStartup
    self.client:ConnectAsync(address)
end

function M:Send(type, data)
    local package = cjson.encode({ type = type, data = data })
    self.client:Send(package)
end

function M:SendData(data)
    local package = cjson.encode(data)
    self.client:Send(package)
end

function M:SendText(text)
    self.client:Send(text)
end

local traceback = debug.traceback
function M:OnPackageReceived(json)
    local package = cjson.decode(json)
    local context = self.serverRequests[package.type]
    if not context then
        warn("Unhandled package", package.type)
        --TODO Mock Test
        --context = self.serverRequests["Test"]
        --local ok, err = xpcall(context.callback, traceback, context.target or package.data, package.data)
        --if not ok then
        --    error(err)
        --end
        return
    end

    local ok, err = xpcall(context.callback, traceback, context.target or package.data, package.data)
    if not ok then
        error(err)
    end
end

function M:OnConnectFailed()
    if self.reconnect == false then
        if SM.GetUIService().GetLoadedUI("NetLoading") then
            SM.GetUIService().Hide("NetLoading")
        end
        local MsgBoxCallbacks = {
            function()
                SM.GetNativeService().ShowChatView()
            end,
            function()
                print("reconnect")
                self.client:Reconnect()
                SM.GetUIService().Show("NetLoading")
                self.showLoading = true
                SM.GetUIService().AfterSceneLoaded()
                self.reconnect = false
            end
        }
        MsgBox.ShowMsgBox("network_reconnect", MsgBoxCallbacks, "MostTop")
        self.showLoading = false
        self.reconnect = true
    end
end

function M:OnReconnect()
    warn("Timeout ,Start Reconnect ")
    _ServerEndData.Login(function(data)
        _ServerEndData.SocketReconnect(data.token)
    end)
end

function M:Tick()
    if not self.client then
        return
    end
    self.client:Tick()

    if self:GetStatus() ~= SocketStatus.Connected then
        if self:GetStatus() == SocketStatus.Connecting then
            self.connectingTime = self.connectingTime + TickService.deltaTime
            if self.connectingTime > 2 then
                self.connectingTime = 0
                self:Close()
            end
        end
        return
    end

    if TickService.realtimeSinceStartup - self.lastHeartBeatTime > 10 then
        --TODO 发送心跳包
        self:SendText("ping")
        self.lastHeartBeatTime = TickService.realtimeSinceStartup
    end
end

function M:SetPauseSocketEvent(shouldPause)
    self.client:SetPauseSocketEvent(shouldPause)
end

function M:RecreateClient()
    self.client = SocketClient(self)
end

function M:Close()
    if not self.client then
        return false
    end
    self.client:Close()
    return true
end

function M:Clear()
    self:Close()
end

function M:_SHeartBeat(package)
    local delay = TickService.realtimeSinceStartup - self.lastHeartBeatTime
    if not SEDService then
        SEDService = SM.GetServerEndDataService()
    end
    SEDService.SetServerTime(package.UtcTime, delay * 0.5)
end

function M:Reconnect(package)
    warn("Reconnect")
    self.client:Close()
    self.client:Reconnect()
end

return M