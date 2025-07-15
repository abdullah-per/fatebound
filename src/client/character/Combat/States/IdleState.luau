--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Main
local IdleState = {}
IdleState.__index = IdleState
setmetatable(IdleState, { __index = BaseState })

function IdleState.new()
	local self = setmetatable(BaseState.new("IdleState"), IdleState)
	return self
end

function IdleState:Enter(stateMachine)
	stateMachine.AnimationHandler:StopAll()
end

function IdleState:HandleInput(stateMachine, input, eventType)
	if eventType ~= "began" then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		stateMachine:ChangeState(stateMachine.States.LightAttackState)
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		stateMachine:ChangeState(stateMachine.States.HeavyAttackState)
	elseif input.KeyCode == Enum.KeyCode.F then
		stateMachine:ChangeState(stateMachine.States.BlockState)
	end
end

return IdleState
