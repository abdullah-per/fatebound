--// Idle State
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)

local IdleState = BaseState.new("IdleState")

function IdleState:Enter(stateMachine)
	print("Idling...")
	stateMachine:ChangeState(stateMachine.States.IdleState)
end

return IdleState
