--[[
    - Base state class.
]]

local BaseState = {}
BaseState.__index = {}

function BaseState.new(stateName: string)
	local self = setmetatable({}, BaseState)

	self.Name = stateName or "DefaultState"
	return self
end

function BaseState:Enter() end

function BaseState:Exit() end

function BaseState:HandleInput(input: InputObject, eventType: string) end

function BaseState:Update(deltaTime) end

return BaseState
