
local M = {}

---@class PlayerClass
---@field position CS.UnityEngine.Vector3
---@field id string
---@field displayName string
---@field gender string
---@field wearing table
local PlayerClass = class()

function PlayerClass:UpdateFromServerData(serverData)
	self.id = serverData.id
	self.displayName = serverData.userName
	self.gender = serverData.gender
	self.wearing = serverData.wearing
end

---@type table<string,PlayerClass>
local allPlayerData = {}

function M.Init()
	allPlayerData = {}
end

function M.GetData()
	return allPlayerData
end

function M.ParseFromServerData(serverData)
	local id = serverData.id
	if id == nil then
		return
	end
	local player = allPlayerData[id]
	if not player then
		player = PlayerClass.new()
		allPlayerData[id] = player
	end
	player:UpdateFromServerData(serverData)
end

function M.RemoverPlayerById(id)
	allPlayerData[id] = nil
end

function M.GetPlayerById(id)
	return allPlayerData[id]
end

return M