local StateController = {}
StateController.__index = StateController

function StateController.new(...)
	local self = setmetatable({}, StateController)

	self.StateMachines = { ... }
	return self
end

function StateController:EnableStates()
	for _, stateMachine in self.StateMachines do
		stateMachine.Enabled = true
	end
end

function StateController:DisableStates()
	for _, stateMachine in self.StateMachines do
		stateMachine.Enabled = false
	end
end

function StateController:EnableState(stateMachineName)
	for _, stateMachine in self.StateMachines do
		if stateMachine.Name == stateMachineName then
			stateMachine.Enabled = true
		end
	end
end

function StateController:DisableState(stateMachineName)
	for _, stateMachine in self.StateMachines do
		if stateMachine.Name == stateMachineName then
			stateMachine.Enabled = false
		end
	end
end

return StateController
