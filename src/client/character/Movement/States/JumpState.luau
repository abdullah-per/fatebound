--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Main
local JumpState = BaseState.new("JumpState")

function JumpState:Enter(stateMachine)
	-- stateMachine.AnimationHandler:Play("Dash_Back")
	-- stateMachine.CameraHandler:ChangeFOV("Jump")
end

function JumpState:HandleInput(stateMachine, input, eventType)
	if input.KeyCode == Enum.KeyCode.Q then
		stateMachine:ChangeState(stateMachine.States.DashState)
	end
end

function JumpState:Update(stateMachine, deltaTime)
	if stateMachine.Humanoid:GetState() == Enum.HumanoidStateType.Landed then
		if InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
			if stateMachine.PreviousState == stateMachine.States.RunState then
				stateMachine:ChangeState(stateMachine.States.RunState)
			else
				stateMachine:ChangeState(stateMachine.States.WalkState)
			end
		else
			stateMachine:ChangeState(stateMachine.States.IdleState)
		end
	end
end

return JumpState
