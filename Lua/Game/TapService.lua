local Finger = CS.DigitalRubyShared.FingerUtil
---@class TapService
local M = {}
local TapList = {}
local PanList = {}
local Pan2List = {}
local ScaleList = {}
function M.Init()
	Finger.RegisterTap(M.Tap)
	Finger.RegisterPan(M.Pan)
	Finger.RegisterPan(M.Pan2, 2)
	Finger.RegisterScale(M.Scale)
end

function M.Register(callback)
	table.insert(TapList, callback)
end

function M.Unregister(callback)
	for index, value in ipairs(TapList) do
		if value == callback then
			table.swap_remove(TapList, index)
		end
	end
end

function M.PanRegister(callback)
	table.insert(PanList, callback)
end

function M.PanUnregister(callback)
	for index, value in ipairs(PanList) do
		if value == callback then
			table.swap_remove(PanList, index)
		end
	end
end

function M.Pan2Register(callback)
	table.insert(Pan2List, callback)
end

function M.Pan2Unregister(callback)
	for index, value in ipairs(Pan2List) do
		if value == callback then
			table.swap_remove(Pan2List, index)
		end
	end
end

function M.ScaleRegister(callback)
	table.insert(ScaleList, callback)
end

function M.ScaleUnregister(callback)
	for index, value in ipairs(ScaleList) do
		if value == callback then
			table.swap_remove(ScaleList, index)
		end
	end
end

function M.clear()
	TapList = {}
	PanList = {}
	Pan2List = {}
	ScaleList = {}
	Finger.UnregisterTap(M.Tap)
	Finger.UnregisterPan(M.Pan)
	Finger.UnregisterPan(M.Pan2)
	Finger.UnregisterScale(M.Scale)
end

function M.Tap(x, y)
	for _, value in ipairs(TapList) do
		value(x, y)
	end
end

function M.Pan(x, y)
	for _, value in ipairs(PanList) do
		value(x, y)
	end
end

function M.Scale(scale)
	for _, value in ipairs(ScaleList) do
		value(scale)
	end
end


function M.Pan2(x, y)
	for _, value in ipairs(Pan2List) do
		value(x, y)
	end
end

return M
