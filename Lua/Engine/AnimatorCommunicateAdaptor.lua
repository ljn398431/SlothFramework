local M = {}

local CommunicatorCallback = {}
function CommunicatorCallback:OnEvent(name)
	local func = self.__unit.currentState[name]
	if func then
		func(self.__unit.currentState)
	end
end

function M.new(communicator, unit)
	local values = {}
	communicator.ParameterSummary.__unit = unit
	setmetatable(communicator.ParameterSummary, { __index = CommunicatorCallback })

	return setmetatable({}, {
		__index = function(_, k)
			local exist = values[k] or communicator[k]
			if exist then
				return exist
			end

			local summary = assert(communicator.ParameterSummary[k], k)
			local animatorVal
			if summary.type == 1 then
				animatorVal = communicator:GetFloat(summary.hash)
			elseif summary.type == 2 then
				animatorVal = communicator:GetInteger(summary.hash)
			elseif summary.type == 3 then
				animatorVal = communicator:GetBool(summary.hash)
			elseif summary.type == 4 then
				animatorVal = function()
					communicator:SetTrigger(summary.hash)
				end
			end

			values[k] = animatorVal
			return animatorVal
		end,
		__newindex = function(_, k, v)
			if k == "controller" then
				communicator:ChangeAnimatorController(v)
				return
			end
			if values[k] == v then
				return
			end

			local summary = assert(communicator.ParameterSummary[k], k)
			if summary.type == 1 then
				communicator:SetFloat(summary.hash, v)
			elseif summary.type == 2 then
				communicator:SetInteger(summary.hash, v)
			elseif summary.type == 3 then
				communicator:SetBool(summary.hash, v)
			else
				assert("animator trigger is not assignable.")
			end
			values[k] = v
		end
	})
end

return M