--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Main
local WalkState = BaseState.new("WalkState")

function WalkState:Enter(stateMachine)
	stateMachine.AnimationHandler:Play("Walk")
	stateMachine.CameraHandler:ChangeFOV("Walk")
	stateMachine.Humanoid.WalkSpeed = stateMachine.WalkSpeed
end

function WalkState:HandleInput(stateMachine, input, eventType)
	if input.KeyCode == Enum.KeyCode.Q then
		stateMachine:ChangeState(stateMachine.States.DashState)
	elseif not InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
		stateMachine:ChangeState(stateMachine.States.IdleState)
	end
end

function WalkState:Update(stateMachine, deltaTime) end

return WalkState
