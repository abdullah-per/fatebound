--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Main
local IdleState = BaseState.new("IdleState")

function IdleState:Enter(stateMachine)
	-- stateMachine.AnimationHandler:Play("Idle")
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

function IdleState:Update(stateMachine, deltaTime) end

return IdleState
