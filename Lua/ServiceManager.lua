local M = {}
local services = {}

M.SERVICE_TYPE = {
	CONFIG = 1,
	TICK = 2,
	CONSOLE_COMMAND = 3,
	UI = 4,
	GLOBAL_VM = 5,
	MOCK = 6,
	GLOBAL_EVENT = 7,
	EVENT_BINDING = 8,
	SERVER_END_DATA = 9,
	NATIVE = 11,
	TAP = 13,
	ACTION = 101,
	PLAYER = 102,
	AVATAR = 103,
	EQUIPMENT = 104,
	GIFT = 105,
	ATMOSPHERE = 106,
	SERVERCONTROLLEDAUDIO = 107,
	PLAYER_COMMAND = 108,
	INTERACTION_OBJECT = 109,
	FULL_QUAD_BLIT = 110,
	FISH = 111
}

function M.GetService(typ)
	return services[typ]
end

---@return ConfigService
function M.GetConfigService()
	return services[M.SERVICE_TYPE.CONFIG]
end

---@return TickService
function M.GetTickService()
	return services[M.SERVICE_TYPE.TICK]
end

---@return Game.ActionService
function M.GetActionService()
	return services[M.SERVICE_TYPE.ACTION]
end

---@return UI.UIService
function M.GetUIService()
	return services[M.SERVICE_TYPE.UI]
end

---@return Game.Network.ServerEndData.ServerEndDataService
function M.GetServerEndDataService()
	return services[M.SERVICE_TYPE.SERVER_END_DATA]
end

---@return base.GlobalEventDispatcher
function M.GetGlobalEventService()
	return services[M.SERVICE_TYPE.GLOBAL_EVENT]
end

function M.UnregisterService(typ)
	local service = services[typ]
	if service and service.clear then
		service.clear()
	end
	services[typ] = nil
end

function M.RegisterService(typ, service)
	assert(service)
	service.Init()
	services[typ] = service
end

function M.Shutdown()
	if _APP.isShutDown then
		return
	end
	for _, typ in pairs(M.SERVICE_TYPE) do
		local service = services[typ]
		if service and service.clear then
			service.clear()
		end
	end
end

_ServiceManager = M

return M