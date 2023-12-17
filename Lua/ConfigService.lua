---@class ConfigService
local M = {}
local ConfigUtil = CS.Extend.LuaUtil.ConfigUtil
local AssetReference = CS.Extend.Asset.AssetReference
local ColorUtility = CS.UnityEngine.ColorUtility
local configs = {}
local math, tonumber, table, ipairs, setmetatable, assert = math, tonumber, table, ipairs, setmetatable, assert
local insert, rawget = table.insert, rawget
local cjson = require "cjson"
local formulaEnv = {}

local linkTypeMetaTable = {
	__index = function(t, k)
		local row = rawget(t, "row")
		if row then
			return row[k]
		end
		local record = M.GetConfigRow(t.configName, t.id)
		t.row = record
		return record[k]
	end
}

local relations = {}
local postprocessor = {}

local columnDataConverter = {
	["int"] = function(data)
		return assert(math.tointeger(data))
	end,
	["number"] = function(data)
		local n = tonumber(data)
		if not n then
			error("data convert number error : ", data)
		end
		return n
	end,
	["string"] = function(data)
		return data
	end,
	["json"] = function(data)
		if data == nil or data == "" then
			return nil
		end
		return assert(cjson.decode(data))
	end,
	["color"] = function(data)
		local success, color = ColorUtility.TryParseHtmlString(data)
		assert(success, data)
		return color
	end,
	["link"] = function(data, configName)
		local id = tonumber(data)
		if id <= 0 then
			return false
		end
		return setmetatable({ id = data, configName = configName }, linkTypeMetaTable)
	end,
	["links"] = function(data, configName)
		local ids = cjson.decode(data)
		local array = {}
		for _, id in ipairs(ids) do
			insert(array, setmetatable({ id = id, configName = configName }, linkTypeMetaTable))
		end
		return array
	end,
	["boolean"] = function(data)
		return data == "1" or data == "true"
	end,
	["bool"] = function(data)
		return data == "1" or data == "true"
	end,
	["translate"] = function()

	end,
	["asset"] = function(data)
		return AssetReference(data)
	end
}

---@param columnType string
---@param data table
local function convert_column_data(data, columnType, colName)
	-- if not data or #data == 0 then
	-- 	assert(columnType == "translate")
	-- end
	assert(data, colName)
	return assert(columnDataConverter[columnType], columnType)(data, colName)
end

local function load_config_data(filename, extends, i18n)
	warn("load_config_data", filename)
	local keyToExtend
	if extends then
		keyToExtend = {}
		for index, v in ipairs(extends) do
			local meta = getmetatable(v)
			local extendKeymap = meta.__keymap
			for k, i in pairs(extendKeymap) do
				if i ~= 1 then
					assert(not keyToExtend[k], k)
					keyToExtend[k] = index
				end
			end
		end
	end
	local processors = postprocessor[filename]
	local textData = ConfigUtil.LoadConfigFile(filename)
	if not textData then
		return
	end
	local keymap = {}
	local config = configs[filename] or setmetatable({}, { __keymap = keymap })
	local max
	for i, key in ipairs(textData.keys) do
		keymap[key] = i
		max = i
	end

	if processors then
		for i, v in ipairs(processors) do
			keymap[v.key] = max + i
		end
	end
	for _, row in ipairs(textData.rows) do
		local typ = textData.types[1]
		local key = textData.keys[1]
		local id = convert_column_data(row[1], typ, key)
		local convertedRow = { id }
		for i = 2, #row do
			typ = textData.types[i]
			key = textData.keys[i]

			if typ == "translate" then
				local i18nConf = i18n[key .. ":" .. id]
				local text = i18nConf and assert(i18nConf[M.currentLanguage]) or ""
				text = text:replace("\\n", "\n")
				table.insert(convertedRow, text)
			else
				table.insert(convertedRow, convert_column_data(row[i], typ, key))
			end
		end

		local meta = {
			__index = function(t, k)
				if keyToExtend then
					local extendIndex = keyToExtend[k]
					if extendIndex then
						local extendRow = assert(extends[extendIndex][id], id)
						return extendRow[k]
					end
				end
				local index = keymap[k]
				if not index then
					warn("Not found key : ", k, "in table", filename)
				else
					return t[index]
				end
			end,
			__tostring = function(t)
				return table.concat(t, ";")
			end
		}
		convertedRow = setmetatable(convertedRow, meta)
		if processors then
			for _, v in ipairs(processors) do
				table.insert(convertedRow, v.processor(convertedRow))
			end
		end
		meta.__newindex = function()
			error("Config don`t have setter")
		end

		config[id] = convertedRow
	end

	configs[filename] = config
	return config, keymap
end

function M.Init()
	--M.GetConfig("AvatarConfig")
end

function M.Reload()
	warn('Reload Config')
	configs = {}
end

---@param name string
function M.GetConfig(name)
	if not configs[name] then
		local extends
		local relateConfNames = relations[name]
		if relateConfNames then
			extends = {}
			for i, confName in ipairs(relateConfNames) do
				extends[i] = M.GetConfig(confName)
			end
		end

		local i18n = load_config_data(name .. "_i18n")
		load_config_data(name, extends, i18n)
	end
	return assert(configs[name], name)
end

---@param name string
---@param id number | string
function M.GetConfigRow(name, id)
	assert(id)
	local config = assert(M.GetConfig(name), name)
	return config[id]
end

---@param id number | string
---@return string
function M.GetLanguageText(id)
	assert(id)
	local config = assert(M.GetConfig("Language"))
	return assert(config[id], id).text
end

---@param filename string
---@return string
function M.PathForFile(filename)
	local row = assert(M.GetConfigRow("PathForResFile", filename), filename)
	return row.path
end

M.currentLanguage = "cn" 
function M.ChangeLanguage(lang)
	M.currentLanguage = lang
end

function M.UnLoad(name)
	configs[name] = nil
end

function M.RegisterPostProcess(tsvName, key, processor)
	local processors = postprocessor[tsvName]
	if not processors then
		processors = {}
		postprocessor[tsvName] = processors
	end
	table.insert(processors, { key = key, processor = processor })
end

function M.SetFormulaVariables(variables)
	table.assign(formulaEnv, variables)
end

function M.clear()
	configs = nil
end

return M