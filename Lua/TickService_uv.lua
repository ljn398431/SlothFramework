local pairs, table, setmetatable = pairs, table, setmetatable
local util = require("util")
local uv = require "luv"

---@class TickService_uv
local M = {}
local tickers = {}
local tickerToAdd = {}

local lateTickers = {}
local lateTickerToAdd = {}

function M.Init()
	setmetatable(tickers, { __mode = "k" })
	setmetatable(lateTickers, { __mode = "k" })
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
	uv.run("nowait")
	local Time = CS.UnityEngine.Time
	M.deltaTime = Time.deltaTime
	M.totalTime = Time.time
	M.timeSinceLevelLoad = Time.timeSinceLevelLoad

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
		
		if not ok then
			M.Unregister(func)
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
		
		if not ok then
			M.UnregisterLate(func)
		end
	end
end

---@param seconds number 超时时间
---@param repeatTimes integer 重复次数， -1无限重复
---@return function 调用后移除
function M.Timeout(seconds, repeatTimes, callback, ...)
	local timer = uv.new_timer()
	local start, interval
	if type(seconds) == "table" then
		start = math.floor(seconds.start * 1000)
		interval = math.floor(seconds.interval * 1000)
	else
		start = math.floor(seconds * 1000)
		interval = math.floor(seconds * 1000)
	end
	local args = table.pack(...)
	timer:start(start, interval, function()
		local ok, complete = util.xpcall_catch(callback, table.unpack(args))
		if not ok or complete == true then
			timer:close()
			timer = nil
			return
		end

		if repeatTimes > 0 then
			repeatTimes = repeatTimes - 1
			if repeatTimes == 0 then
				timer:close()
				timer = nil
			end
		end
	end)
	return function()
		if not timer then
			return
		end
		timer:close()
		timer = nil
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