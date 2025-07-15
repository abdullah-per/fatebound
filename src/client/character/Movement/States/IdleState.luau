--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Main
local IdleState = {}
IdleState.__index = IdleState
setmetatable(IdleState, { __index = BaseState })

function IdleState.new()
	local self = setmetatable(BaseState.new("IdleState"), IdleState)
	return self
end

function IdleState:Enter(stateMachine)
	if not stateMachine.AnimationHandler:IsPlaying("Idle") then
		stateMachine.AnimationHandler:Play("Idle")
	end
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
