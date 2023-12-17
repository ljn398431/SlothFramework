local pairs, table, setmetatable = pairs, table, setmetatable
local util = require("util")

---@class TickService
local M = {}
local tickers = {}
local tickerToAdd = {}

local lateTickers = {}
local lateTickerToAdd = {}

local timeouts = {}
local nTimeOutUid = 1

function M.Init()
	setmetatable(tickers, { __mode = "k" })
	setmetatable(lateTickers, { __mode = "k" })

	local Time = CS.UnityEngine.Time
	M.deltaTime = math.min(Time.deltaTime, 0.05)
	M.totalTime = Time.time
	M.timeSinceLevelLoad = Time.timeSinceLevelLoad
	M.realtimeSinceStartup = Time.realtimeSinceStartup
end

function M.clear()
	warn("Clear tick")
	tickers = {}
	lateTickers = {}
	tickerToAdd = {}
	lateTickerToAdd = {}
end

function M.Register(func, ...)
	local packed = table.pack(...)
	tickerToAdd[func] = packed
end

function M.RegisterLate(func, ...)
	local packed = table.pack(...)
	lateTickerToAdd[func] = packed
end

function M.Tick()
	local Time = CS.UnityEngine.Time
	M.deltaTime = math.min(Time.deltaTime, 0.05)
	M.totalTime = Time.time
	M.timeSinceLevelLoad = Time.timeSinceLevelLoad
	M.realtimeSinceStartup = Time.realtimeSinceStartup

	for func, pack in pairs(tickerToAdd) do
		tickers[func] = pack
	end
	tickerToAdd = {}

	for func, packed in pairs(tickers) do
		local ok
		if packed.n ~= 0 then
			ok = util.xpcall_catch(func, table.unpack(packed))
		else
			ok = util.xpcall_catch(func)
		end
	end
	
	for uid, timeout in pairs(timeouts) do
		timeout.timeToTrigger = timeout.timeToTrigger - M.deltaTime
		if timeout.timeToTrigger < 0 then
			local ok, complete
			if timeout.params.n ~= 0 then
				ok, complete = util.xpcall_catch(timeout.callback, table.unpack(timeout.params))
			else
				ok, complete = util.xpcall_catch(timeout.callback)
			end
			
			if timeout.repeatTimes > 0 then
				timeout.repeatTimes = timeout.repeatTimes - 1
			end
			
			if not ok then
				error(complete)
				timeouts[uid] = nil
			elseif complete or timeout.repeatTimes == 0 then
				timeouts[uid] = nil
			else
				timeout.timeToTrigger = timeout.interval
			end
		end
	end
end

function M.LateTick()
	for func, pack in pairs(lateTickerToAdd) do
		lateTickers[func] = pack
	end
	lateTickerToAdd = {}

	for func, packed in pairs(lateTickers) do
		local ok
		if packed.n ~= 0 then
			ok = util.xpcall_catch(func, table.unpack(packed))
		else
			ok = util.xpcall_catch(func)
		end
	end
end

---@param seconds number 超时时间
---@param repeatTimes integer 重复次数， -1无限重复
---@return function 调用后移除
function M.Timeout(seconds, repeatTimes, callback, ...)
	local start, interval
	if type(seconds) == "table" then
		start = seconds.start
		interval = seconds.interval
	else
		start = seconds
		interval = seconds
	end
	
	nTimeOutUid = nTimeOutUid + 1
	timeouts[nTimeOutUid] = {
		timeToTrigger = start,
		interval = interval,
		repeatTimes = repeatTimes,
		callback = callback,
		params = table.pack(...)
	}
	local uid = nTimeOutUid
	return function()
		timeouts[uid] = nil
	end
end

function M.Unregister(func)
	tickerToAdd[func] = nil
	tickers[func] = nil
end

function M.UnregisterLate(func)
	lateTickerToAdd[func] = nil
	lateTickers[func] = nil
end

return M