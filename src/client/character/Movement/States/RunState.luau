--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Main
local RunState = {}
RunState.__index = RunState
setmetatable(RunState, { __index = BaseState })

function RunState.new()
	local self = setmetatable(BaseState.new("RunState"), RunState)
	return self
end

function RunState:Enter(stateMachine)
	if not stateMachine.AnimationHandler:IsPlaying("Run") then
		stateMachine.AnimationHandler:Play("Run")
	end
	stateMachine.CameraHandler:ChangeFOV("Run")
	stateMachine.Humanoid.WalkSpeed = stateMachine.Controller.PlayerConfigs.RunSpeed
end

function RunState:HandleInput(stateMachine, input, eventType)
	if input.KeyCode == Enum.KeyCode.Q then
		stateMachine:ChangeState(stateMachine.States.DashState)
	elseif input.KeyCode == Enum.KeyCode.Space then
		stateMachine:ChangeState(stateMachine.States.JumpState)
	elseif not InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
		stateMachine:ChangeState(stateMachine.States.IdleState)
	end
end

return RunState
