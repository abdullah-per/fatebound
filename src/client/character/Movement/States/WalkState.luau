--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Main
local WalkState = {}
WalkState.__index = WalkState
setmetatable(WalkState, { __index = BaseState })

function WalkState.new()
	local self = setmetatable(BaseState.new("WalkState"), WalkState)
	return self
end

function WalkState:Enter(stateMachine)
	if not stateMachine.AnimationHandler:IsPlaying("Walk") then
		stateMachine.AnimationHandler:Play("Walk")
	end
	stateMachine.CameraHandler:ChangeFOV("Walk")
	stateMachine.Humanoid.WalkSpeed = stateMachine.Controller.PlayerConfigs.WalkSpeed
end

function WalkState:HandleInput(stateMachine, input, eventType)
	if input.KeyCode == Enum.KeyCode.Q then
		stateMachine:ChangeState(stateMachine.States.DashState)
	elseif input.KeyCode == Enum.KeyCode.Space then
		stateMachine:ChangeState(stateMachine.States.JumpState)
	elseif not InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
		stateMachine:ChangeState(stateMachine.States.IdleState)
	end
end

function WalkState:Update(stateMachine, deltaTime) end

return WalkState
