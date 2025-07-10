--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StartPageService = game:GetService("StartPageService")

--// Imports
local Spring = require(ReplicatedStorage.Shared.External.Spring)
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local BackDash = require(ReplicatedStorage.Shared.Movement.BackDash)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Configs
local GHOST_TIME = 1
local CURRENT_GHOST_TIME = 0

--// Instances
local DashSpring = Spring.create(Spring, 7)

--// Main
local DashState = BaseState.new("DashState")

local waitForGhost = false
function DashState:Enter(stateMachine)
	stateMachine.CameraHandler:ChangeFOV("Dash")

	if InputHandler.AllPressed(Enum.KeyCode.S) then -- back
		stateMachine.AnimationHandler:Play("Dash_Back")
		DashSpring.shove(DashSpring, Vector3.new(0, 0, stateMachine.BackDashDistance))

		-- ghost dash logic
		CURRENT_GHOST_TIME = GHOST_TIME
		stateMachine.Humanoid.WalkSpeed = 30

		waitForGhost = true
		local ragdoll = BackDash.Enable(stateMachine.Character)
		task.wait(CURRENT_GHOST_TIME)
		BackDash.Disable(stateMachine.Character, ragdoll)
		waitForGhost = false

		return
	elseif InputHandler.AllPressed(Enum.KeyCode.A) then -- left
		stateMachine.AnimationHandler:Play("Dash_Left")
		DashSpring.shove(DashSpring, Vector3.new(-stateMachine.SideDashDistance, 0, 0))
	elseif InputHandler.AllPressed(Enum.KeyCode.D) then -- right
		stateMachine.AnimationHandler:Play("Dash_Right")
		DashSpring.shove(DashSpring, Vector3.new(stateMachine.SideDashDistance, 0, 0))
	else
		-- auto lock logic
		stateMachine.AnimationHandler:Play("Dash_Front")
		DashSpring.shove(DashSpring, Vector3.new(0, 0, -stateMachine.FrontDashDistance))
	end

	CURRENT_GHOST_TIME = 0
end

local accumulatedTime = 0
function DashState:Update(stateMachine, deltaTime)
	if accumulatedTime <= 0.4 then
		accumulatedTime += deltaTime
		local UpdatedPosition = DashSpring.update(DashSpring, deltaTime)
		stateMachine.HumanoidRP.CFrame *= CFrame.new(UpdatedPosition.X, UpdatedPosition.Y, UpdatedPosition.Z)
	else
		if waitForGhost then
			return
		end

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

return DashState
