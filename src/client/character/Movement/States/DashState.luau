--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StartPageService = game:GetService("StartPageService")

--// Imports
local Spring = require(ReplicatedStorage.Shared.External.Spring)
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local BackDash = require(ReplicatedStorage.Shared.Movement.BackDash)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Configs
local CURRENT_GHOST_TIME = 0

--// Instances
local DashSpring = Spring.create(Spring, 7)

--// Main
local DashState = BaseState.new("DashState")

local waitForGhost = false
local accumulatedTime = 0
function DashState:Enter(stateMachine)
	local playerConfigs = stateMachine.Controller.PlayerConfigs
	if InputHandler.AllPressed(Enum.KeyCode.S) and playerConfigs.DashCharges >= 3 then -- back
		stateMachine.AnimationHandler:Play("Dash_Back")
		stateMachine.CameraHandler:ChangeFOV("Dash")

		playerConfigs.DashCharges = 0

		task.spawn(function()
			task.wait(stateMachine.AnimationHandler.Tracks.Dash_Back.Length + 0.1)
			stateMachine.AnimationHandler:Play("Ghost_Idle")
		end)

		stateMachine.SoundHandler:Play("Dash_Back")
		DashSpring.shove(DashSpring, Vector3.new(0, 0, playerConfigs.BackDashDistance))

		-- ghost dash logic
		CURRENT_GHOST_TIME = stateMachine.SoundHandler.Tracks.Dash_Back.TimeLength
		stateMachine.Humanoid.WalkSpeed = 30

		waitForGhost = true
		local ragdoll = BackDash.Enable(stateMachine.Character)
		task.wait(CURRENT_GHOST_TIME)
		BackDash.Disable(stateMachine.Character, ragdoll)
		waitForGhost = false

		return
	elseif InputHandler.AllPressed(Enum.KeyCode.A) and playerConfigs.DashCharges >= 1 then -- left
		stateMachine.AnimationHandler:Play("Dash_Left")
		stateMachine.SoundHandler:Play("Dash_Side")
		stateMachine.CameraHandler:ChangeFOV("Dash")

		playerConfigs.DashCharges -= 1
		DashSpring.shove(DashSpring, Vector3.new(-playerConfigs.SideDashDistance, 0, 0))
	elseif InputHandler.AllPressed(Enum.KeyCode.D) and playerConfigs.DashCharges >= 1 then -- right
		stateMachine.AnimationHandler:Play("Dash_Right")
		stateMachine.SoundHandler:Play("Dash_Side")
		stateMachine.CameraHandler:ChangeFOV("Dash")

		playerConfigs.DashCharges -= 1
		DashSpring.shove(DashSpring, Vector3.new(playerConfigs.SideDashDistance, 0, 0))
	elseif
		not InputHandler.AnyPressed(Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D)
		and playerConfigs.DashCharges >= 2
	then
		-- auto lock logic
		stateMachine.AnimationHandler:Play("Dash_Front")
		stateMachine.SoundHandler:Play("Dash_Side")
		stateMachine.CameraHandler:ChangeFOV("Dash")
		playerConfigs.DashCharges -= 2
		DashSpring.shove(DashSpring, Vector3.new(0, 0, -playerConfigs.FrontDashDistance))
	else
		accumulatedTime += 0.4
		print("NOT ENOUGH CHARGES!!!")
	end

	CURRENT_GHOST_TIME = 0 -- resetting ghost
end

function DashState:Update(stateMachine, deltaTime)
	if accumulatedTime <= stateMachine.Controller.PlayerConfigs.DashDuration then
		accumulatedTime += deltaTime
		local UpdatedPosition = DashSpring.update(DashSpring, deltaTime)
		stateMachine.HumanoidRP.CFrame *= CFrame.new(UpdatedPosition.X, UpdatedPosition.Y, UpdatedPosition.Z)
	else
		if waitForGhost then
			return
		end

		accumulatedTime = 0 -- reset for next dash

		if InputHandler.AllPressed(Enum.KeyCode.Q) then
			DashState:Enter(stateMachine)
		elseif InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
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
