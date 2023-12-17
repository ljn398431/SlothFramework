local SM = require("ServiceManager")

local M = {}
local enable = true
local isSimulating = CS.UnityEngine.Application.isEditor

M.PriorityTypes = {
	Gift = 1,
	Fishing = 2
}

M.prioritise = {}
M.maxPriority = 0

---@param newEnableState boolean
function M.SetEnable(newEnableState)
	enable = newEnableState
end

function M.RegisterVibrationOwner(name)
	local priority = assert(M.PriorityTypes[name], name)
	M.prioritise[name] = priority

	if M.maxPriority < priority then
		M.maxPriority = priority
	end
end

function M.UnregisterVibrationOwner(name)
	M.prioritise[name] = nil
	local maxPriority = 0
	for _, priority in pairs(M.prioritise) do
		if maxPriority < priority then
			maxPriority = priority
		end
	end
	M.maxPriority = maxPriority
end

---@param intensity number
function M.VibrateOnce(name, intensity)
	if not enable then
		return
	end
	local priority = assert(M.PriorityTypes[name], name)
	if M.maxPriority > priority then
		return
	end

	M.NativeDeviceVibrate(intensity)
	if isSimulating then print("Beep...") end
end

function M.NativeDeviceVibrate(intensity)
	SM.GetNativeService().SendToNative("ImpactFeedbackGenerator", {intensity = intensity})
end

return M
