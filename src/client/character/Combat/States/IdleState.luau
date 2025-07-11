--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Main
local IdleState = BaseState.new("IdleState")

function IdleState:Enter(stateMachine)
	stateMachine.AnimationHandler:Play("Idle")
	stateMachine.CameraHandler:ChangeFOV("Idle")
end

local lastW = os.clock()
function IdleState:HandleInput(stateMachine, input, eventType)
	if input.KeyCode == Enum.KeyCode.Q then
		stateMachine:ChangeState(stateMachine.States.DashState)
	elseif input.KeyCode == Enum.KeyCode.Space then
		stateMachine:ChangeState(stateMachine.States.JumpState)
	elseif input.KeyCode == Enum.KeyCode.W then
		if os.clock() - lastW <= 0.25 then
			stateMachine:ChangeState(stateMachine.States.RunState)
		else
			stateMachine:ChangeState(stateMachine.States.WalkState)
		end

		lastW = os.clock()
	elseif InputHandler.AnyPressed(Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
		stateMachine:ChangeState(stateMachine.States.WalkState)
	end
end

function IdleState:Update(stateMachine, deltaTime) end

return IdleState
