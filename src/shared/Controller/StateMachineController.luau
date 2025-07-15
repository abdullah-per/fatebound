--// State machine controller
local StateController = {}
StateController.__index = StateController

StateController.PlayerConfigs = nil

function StateController.new(...)
	local self = setmetatable({}, StateController)
	self.StateMachines = { ... }

	--// setting a controller property on each state machine for internal access
	for _, stateMachine in self.StateMachines do
		stateMachine.Controller = self
	end

	return self
end

function StateController:EnableAllStates()
	for _, stateMachine in self.StateMachines do
		stateMachine:Enable()
	end
end

function StateController:DisableAllStates()
	for _, stateMachine in self.StateMachines do
		stateMachine:Disable()
	end
end

function StateController:EnableStateMachine(stateMachine)
	for _, listedStateMachine in self.StateMachines do
		if listedStateMachine == stateMachine then
			listedStateMachine:Enable()
		end
	end
end

function StateController:DisableStateMachine(stateMachine)
	for _, listedStateMachine in self.StateMachines do
		if listedStateMachine == stateMachine then
			listedStateMachine:Disable()
		end
	end
end

function StateController:SetStateMachineEnabled(stateMachine, enabled)
	for _, listedStateMachine in self.StateMachines do
		if listedStateMachine == stateMachine then
			if enabled then
				listedStateMachine:Enable()
			else
				listedStateMachine:Disable()
			end
		end
	end
end

function StateController:SetStateMachines(stateMachines)
	self.StateMachines = stateMachines
end

return StateController
