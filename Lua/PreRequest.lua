require("util")
require("QualitySelect")

function Global_ShowLogFile()
	local path = CS.UnityEngine.Application.persistentDataPath .. "/error.log"
	local f = io.open(path, "rb")
	local file = f:read("a")
	f:close()
	return file
end

function Global_DebugFunction(lua)
	local _, ret = xpcall(function()
		local func = load(lua)
		return func()
	end, debug.traceback)
	return tostring(ret)
end

local SM = require "ServiceManager"
local ConfigService = require "ConfigService"
local TS = require "TickService"

local CmdService = require("CommandService")
local UIService = require "UI.UIService"
local GlobalVMService = require "mvvm.GlobalVMService"
local MockService = require("base.MockService")
local EventBindingService = require("base.EventBindingService")
local ServerEndDataService = require("Game.Network.ServerEndData.ServerEndDataService")
local GlobalEventDispatcher = require("base.GlobalEventDispatcher")
local binding = require("mvvm.binding")


SM.RegisterService(SM.SERVICE_TYPE.CONFIG, ConfigService)
SM.RegisterService(SM.SERVICE_TYPE.TICK, TS)
SM.RegisterService(SM.SERVICE_TYPE.CONSOLE_COMMAND, CmdService)
SM.RegisterService(SM.SERVICE_TYPE.GLOBAL_VM, GlobalVMService)
SM.RegisterService(SM.SERVICE_TYPE.MOCK, MockService)
SM.RegisterService(SM.SERVICE_TYPE.EVENT_BINDING, EventBindingService)
SM.RegisterService(SM.SERVICE_TYPE.GLOBAL_EVENT, GlobalEventDispatcher)
SM.RegisterService(SM.SERVICE_TYPE.SERVER_END_DATA, ServerEndDataService)

local app
return {
	init = function()
		SM.RegisterService(SM.SERVICE_TYPE.UI, UIService)
		--	require("ConfigServicePostProcess")
		
		-- Unity
		binding.SetEnvVariable({
			UnityColor = CS.UnityEngine.Color
		})

		-- Service
		binding.SetEnvVariable({
			ConfigService = ConfigService
		})

		local Application = require("Game.Application")
		app = Application.new()
		app:Init()

		-- Lua
		binding.SetEnvVariable(_G)
	end,
	shutdown = function()
		if app then
			app:Shutdown()
		end
		SM.Shutdown()
	end,
	clearCache = function()
		for k, _ in pairs(package.loaded) do
			package.loaded[k] = false
		end
	end
}