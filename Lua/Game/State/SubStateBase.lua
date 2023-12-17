---@class Game.State.SubStateBase
local M = class()
M.Conflict = {
	NONE = 0,
	NPC_ICON_CLICK = 1,	--点击NPC图标
	HIDE_SEEK = 2, 		--捉迷藏
	GIFT = 4, 			--寻宝
	ALL = 2048-1,
}
-- abstract
function M:Enter()
end

function M:Update()
end

-- abstract
function M:Exit()
end

function M:GetIsReady()
	return false
end

function M:GetStateType()

end

function M:ShowStatusIcon()
end

function M:GetConflictMask()
	return M.Conflict.ALL
end

function M:GetStateName()
	
end

function M:Clear()
end

return M