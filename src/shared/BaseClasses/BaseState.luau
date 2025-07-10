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

function BaseState:Enter(stateMachine) end

function BaseState:Exit(stateMachine) end

function BaseState:HandleInput(stateMachine, input: InputObject, eventType: string) end

function BaseState:Update(stateMachine, deltaTime) end

return BaseState
