--[[
    - Base state class.
]]

local BaseState = {}
BaseState.__index = BaseState

function BaseState.new(stateName: string)
	local self = setmetatable({}, BaseState)

	self.Name = stateName or "DefaultState"
	return self
end

function BaseState:Enter(stateMachine)
	print("Debug | State entered: " .. self.Name)
end

function BaseState:Exit(stateMachine)
	print("Debug | State exited: " .. self.Name)
end

function BaseState:HandleInput(stateMachine, input: InputObject, eventType: string)
	print("Debug | State input handled: " .. self.Name)
end

function BaseState:Update(stateMachine, deltaTime)
	print("Debug | State updated: " .. self.Name)
end

return BaseState
