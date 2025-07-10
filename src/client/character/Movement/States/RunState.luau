--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Main
local RunState = BaseState.new("RunState")

function RunState:Enter(stateMachine)
	print("Running...")
	stateMachine.CameraHandler:ChangeFOV("Run")
	stateMachine.Humanoid.WalkSpeed = stateMachine.RunSpeed
end

function RunState:HandleInput(stateMachine, input, eventType)
	if input.KeyCode == Enum.KeyCode.Q then
		stateMachine:ChangeState(stateMachine.States.DashState)
	elseif not InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
		stateMachine:ChangeState(stateMachine.States.IdleState)
	end
end

function RunState:Update(stateMachine, deltaTime) end

return RunState
