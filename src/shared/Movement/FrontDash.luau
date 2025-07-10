--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local Spring = require(ReplicatedStorage.Shared.External.Spring)
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Instances
local DashSpring = Spring.create(Spring, 7)

--// Main
local FrontDashState = BaseState.new("FrontDashState")

function FrontDashState:Enter(stateMachine)
	-- initiating dash
	stateMachine.CameraHandler:ChangeFOV("Dash")
	stateMachine.AnimationHandler:Play("Dash_Front")

	DashSpring.shove(DashSpring, Vector3.new(0, 0, -stateMachine.FrontDashDistance))
end

local accumulatedTime = 0
function FrontDashState:Update(stateMachine, deltaTime)
	if accumulatedTime <= 0.4 then
		accumulatedTime += deltaTime
		local UpdatedPosition = DashSpring.update(DashSpring, deltaTime)
		stateMachine.HumanoidRP.CFrame *= CFrame.new(UpdatedPosition.X, UpdatedPosition.Y, UpdatedPosition.Z)
	else
		accumulatedTime = 0 -- reset for next dash

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

return FrontDashState
