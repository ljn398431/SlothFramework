local setmetatable, getmetatable, rawset, rawget, pairs, type, ipairs, xpcall = setmetatable, getmetatable, rawset, rawget, pairs, type, ipairs, xpcall
local insert, concat, remove, unpack = table.insert, table.concat, table.remove, table.unpack
local find, format, sub, gsub = string.find, string.format, string.sub, string.gsub
local tonumber, tostring = tonumber, tostring
local next, assert = next, assert
local Vector3 = CS.UnityEngine.Vector3

string.replace = function(s, pattern, repl)
	local i, j = find(s, pattern, 1, true)
	if i and j then
		local ret = {}
		local start = 1
		while i and j do
			insert(ret, sub(s, start, i - 1))
			insert(ret, repl)
			start = j + 1
			i, j = find(s, pattern, start, true)
		end
		insert(ret, sub(s, start))
		return concat(ret)
	end
	return s
end

string.replace_with_table = function(s, t)
	return gsub(s, "%$(%w+)", t)
end

---@param fmt string
string.format_text = function(fmt, ...)
	assert(fmt ~= nil, "format is nil")
	local params = {...}
	local function search(k)
		k = assert(tonumber(k), k)
		assert(k <= #params, "Index out of range")
		return tostring(params[k])
	end
	return fmt:gsub("%{(%d)}$", search)
end

string.split = function(s, delimiter)
	local result = {}
	local from = 1
	local f, t = find(s, delimiter, from, true)
	while f do
		insert(result, sub(s, from, f - 1))
		from = t + 1
		f, t = find(s, delimiter, from, true)
	end
	insert(result, sub(s, from))
	return result
end

string.splitToNumber = function(s, delimiter)
	local result = {}
	local from = 1
	local f, t = find(s, delimiter, from, true)
	while f do
		insert(result, tonumber(sub(s, from, f - 1)))
		from = t + 1
		f, t = find(s, delimiter, from, true)
	end
	insert(result, tonumber(sub(s, from)))
	return result
end

string.caseInsensitive = function(s)
	s = string.gsub(s, "%a", function (c)
		return string.format("[%s%s]", string.lower(c), string.upper(c))
	end)
	return s
end

function string.fromhex(str)
	return (str:gsub('..', function (cc)
		return string.char(tonumber(cc, 16))
	end))
end

function string.tohex(str)
	return (str:gsub('.', function (c)
		return string.format('%02X', string.byte(c))
	end))
end

function string.startWith(s, pattern)
	if #s < #pattern then
		return false
	end
	return string.sub(s, 1, string.len(pattern)) == pattern
end

function string.isNullOrEmpty(s)
	return not s or s == ""
end

function table.empty(t)
	return next(t) == nil
end

function table.array_each(t, callback)
	for i = 1, #t do
		callback(t[i], i)
	end
end

function table.table_each(t, callback)
	for k, v in pairs(t) do
		callback(v, k)
	end
end

function table.index_of(t, val)
	for i = 1, #t do
		if val == t[i] then
			return i
		end
	end
	return -1
end

function table.array_find(t, val)
	local index = table.index_of(t, val)
	if index == -1 then
		return
	end
	return t[index]
end

function table.array_find_predict(t, func)
	local index = table.index_of_predict(t, func)
	if index == -1 then
		return
	end
	return t[index]
end

function table.index_of_predict(t, func)
	for i = 1, #t do
		if func(t[i]) then
			return i
		end
	end
	return -1
end

function table.swap_remove(t, index)
	if not index then
		index = 1
	end
	t[index] = t[#t]
	return remove(t, #t)
end

function table.count(t)
	local count = 0
	for key, value in pairs(t) do
		count = count + 1
	end
	return count
end

function table.copy(t)
	local ret = {}
	for key, value in pairs(t) do
		if type(value) == "table" then
			ret[key] = table.copy(value)
		else
			ret[key] = value
		end
	end
	return ret
end

function table.sum(t, selector)
	local sum = 0
	if not selector then
		for _, v in pairs(t) do
			sum = sum + v
		end
	else
		if type(selector) == "string" then
			for _, v in pairs(t) do
				sum = sum + v[selector]
			end
		else
			for k, v in pairs(t) do
				sum = sum + selector(v, k)
			end
		end
	end
	
	return sum
end

local floor = math.floor
function math.round(value)
	return floor(value + 0.5)
end

function math.clamp(v, minValue, maxValue)
	if v < minValue then
		return minValue
	end
	if v > maxValue then
		return maxValue
	end
	return v
end

function math.clamp01(v)
	return math.clamp(v, 0, 1)
end

function math.lerp(a, b, t)
	return a + (b - a) * t
end

local function dump(t)
	if t == nil then return "nil" end
	local log = ""
	local print_r_cache = {}
	local function sub_print_r(t, indent)
		if (print_r_cache[tostring(t)]) then
			log = log .. indent .. "*" .. tostring(t)
		else
			print_r_cache[tostring(t)] = true
			if type(t) == "table" then
				for pos, val in pairs(t) do
					if type(val) == "table" then
						log = log .. indent .. "[" .. pos .. "] => " .. tostring(t) .. " {\n"
						sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8))
						log = log .. indent .. string.rep(" ", string.len(pos) + 6) .. "}\n"
					elseif (type(val) == "string") then
						log = log .. indent .. "[" .. pos .. '] => "' .. val .. '"\n'
					else
						log = log .. indent .. "[" .. pos .. "] => " .. tostring(val) .. '\n'
					end
				end
			else
				log = log .. indent .. tostring(t) .. "\n"
			end
		end
	end
	if type(t) == "table" then
		log = log .. tostring(t) .. " {\n"
		sub_print_r(t, "  ")
		log = log .. "} \n"
	else
		sub_print_r(t, "  ")
	end
	return log
end

local function dumpLua(val, showMetatable, indentLevel, indentChar)
	if val == nil then return "nil" end
	if showMetatable == nil then showMetatable = true end
	indentLevel = indentLevel or 0
	if indentLevel > 10 then
		return "nil, -- Recursion is Too Deep..."
	end
	indentChar = indentChar or "\t"
	local tc = {}
	if type(val) == "table" then
		tc[#tc + 1] = string.format("{ -- ID: %s\n", tostring(val))
		if showMetatable then
			local mt = getmetatable(val)
			if mt then
				tc[#tc + 1] = string.format("%s__metatable = %s, \n", string.rep(indentChar, indentLevel + 1), dumpLua(mt, showMetatable, indentLevel + 1, indentChar))
			end
		end
		for k, v in pairs(val) do
			if type(k) == "number" and k == math.floor(k) then
				tc[#tc + 1] = string.format("%s-- [%d]:\n", string.rep(indentChar, indentLevel + 1), k)
				tc[#tc + 1] = string.format("%s%s,\n", string.rep(indentChar, indentLevel + 1), dumpLua(v, showMetatable, indentLevel + 1, indentChar))
			else
				tc[#tc + 1] = string.format("%s%s = %s,\n", string.rep(indentChar, indentLevel + 1), tostring(k), dumpLua(v, showMetatable, indentLevel + 1, indentChar))
			end
		end
		tc[#tc + 1] = string.rep(indentChar, indentLevel).."}"
	elseif type(val) == "function" then
		tc[#tc + 1] = string.format("function () end -- %s", tostring(val))
	elseif type(val) == "string" then
		tc[#tc + 1] = "\""..val.."\""
	elseif type(val) == "userdata" then
		tc[#tc + 1] = string.format("nil, -- UserData: %s", tostring(val))
	else
		tc[#tc + 1] = tostring(val)
	end
	local log = table.concat(tc)
		return log
end

table.print_r = function(t)
	print(dump(t))
end

table.dump_r = function(t)
	return dump(t)
end

table.dump_asLua = function(t, tName)  
	return tName and tName.." = "..dumpLua(t, false) or (dumpLua(t, false))
end

table.print_asLua = function(t, tName)
	print(table.dump_asLua(t, tName))
end

table.dump_asLuaWithMT= function(t, tName)
	return tName and tName.." = "..dumpLua(t, true) or (dumpLua(t, true))
end

table.print_asLuaWithMT = function(t, tName)
	print(table.dump_asLuaWithMT(t, tName))
end

table.assign = function(source, t)
	source = source or {}
	for k, v in pairs(t) do
		source[k] = v
	end
	return source
end

table.add_range = function(source, t)
	for i, v in ipairs(t) do
		source[#source + i] = v
	end
end

table.packFunc = function (t)
    local mt = {}
	mt.__call = function (ts)
		for index, func in ipairs(ts) do
			func()
		end
	end
	setmetatable(t, mt)
	return t
end

local traceback = debug.traceback
local xpcall_catch = function(f, ...)
	if not f then
		return
	end
	local ok, err = xpcall(f, traceback, ...)
	if not ok then
		error(err)
	end

	return ok, err
end

local resume = coroutine.resume
local catch_resume = function(co, param1)
	local ok, err = resume(co, param1)
	if not ok then
		error(err)
	end
end

local function parse_path(path)
	if not path or path == '' then error('invalid path:' .. tostring(path)) end
	local result = {}
	local i, n = 1, #path
	while i <= n do
		local s, e, split1, key, split2 = find(path, "([%.%[])([^%.^%[^%]]+)(%]?)", i)
		if not s or s > i then
			insert(result, sub(path, i, s and s - 1))
		end
		if not s then break end
		if split1 == '[' then
			if split2 ~= ']' then error('invalid path:' .. path) end
			key = tonumber(key)
			if not key then error('invalid path:' .. path) end
			insert(result, key)
		else
			insert(result, key)
		end
		i = e + 1
	end
	return result
end

local function gen_callback_func(tbl, path, callback)
	local keys = parse_path(path)
	local final
	local finalKey
	for index, key in ipairs(keys) do
		if #keys == index then
			finalKey = key
			break
		end
		final = tbl[key]
	end
	final.__notifications = final.__notifications or {}
	local notifications = final.__notifications[finalKey] or {}
	insert(notifications, callback)
	final.__notifications[finalKey] = notifications
end

local move_end = {}

local generator_mt = {
	__index = {
		MoveNext = function(self)
			self.Current = self.co()
			if self.Current == move_end then
				self.Current = nil
				return false
			else
				return true
			end
		end;
		Reset = function(self)
			self.co = coroutine.wrap(self.w_func)
		end
	}
}

local function cs_generator(func, ...)
	local params = {...}
	local generator = setmetatable({
		w_func = function()
			func(unpack(params))
			return move_end
		end
	}, generator_mt)
	generator:Reset()
	return generator
end

local isInScallopedArea = function(playerTransform,targetPos,maxDistance,maxAngle)
	local tarDir = targetPos - playerTransform.position
	local distance = Vector3.Distance(playerTransform.position,targetPos)
	local angle = Vector3.Angle(playerTransform.forward,tarDir)
	if angle <= maxAngle and distance <= maxDistance then
		return true
	end
	return false
end

DestroyedTableMeta = {
	__index = function(t, k)
		error("Lua table has been destroyed, dont try to visit", t, k)
	end,
	__newindex = function(t, k, v)
		error("Lua table has been destroyed, dont try to visit", t, k, v)
	end
}

---@param t table
---@param onElementAdd function
---@param onElementDelete function
---@param onElementUpdate function
---@param elementEqFunc function
---@return table
---@See See: "Programming in Lua : Chapter 20. Metatables and Metamethods : Tracking Table Access"
function TrackUpdating(t, onElementAdd, onElementDelete, onElementUpdate, elementEqFunc)
	local proxy = {}
	local mt = {
		__index = function (_, k)
			return t[k]
		end,

		__newindex = function(_, k, newElement)
			local oldElement = t[k]
			if oldElement == nil then
				t[k] = newElement
				if onElementAdd ~= nil then onElementAdd(k, newElement) end
			else
				if newElement == nil then
					t[k] = newElement
					if onElementDelete ~= nil then onElementDelete(k, oldElement) end
				elseif (elementEqFunc == nil and newElement ~= oldElement) or (elementEqFunc ~= nil and not elementEqFunc(newElement, oldElement)) then
					t[k] = newElement
					if onElementUpdate ~= nil then onElementUpdate(k, oldElement, newElement) end
				end
			end
		end,
		__pairs = function()
			return function(_, k)
				local nextKey, nextValue = next(t, k)
				return nextKey, nextValue
			end
		end,

		__len = function() return #t end
	}

	function proxy.Update(newList)
		for oldKey, _ in pairs(proxy) do
			if newList[oldKey] == nil then
				proxy[oldKey] = nil
			end
		end
		for k, v in pairs(newList) do
			proxy[k] = v
		end
	end

	setmetatable(proxy, mt)
	return proxy
end


function _VersionCompare(ver1, ver2)
	if CS.UnityEngine.Application.isEditor then
		return true
	end

	local _, _, v1, v2, v3 = string.find(ver1, "(%d+)%.(%d+)%.(%d+)")
	local _, _, r1, r2, r3 = string.find(ver2, "(%d+)%.(%d+)%.(%d+)")
	if r1 or r2 or r3 then
		return v1 * 10000 + v2 * 100 + v3 >= r1 * 10000 + r2 * 100 + r3
	end
	return false
end

return {
	parse_path = parse_path,
	cs_generator = cs_generator,
	gen_callback_func = gen_callback_func,
	xpcall_catch = xpcall_catch,
	catch_resume = catch_resume,
	isInScallopedArea = isInScallopedArea
}