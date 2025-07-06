--// Movement State Machine
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseMachine = require(ReplicatedStorage.Shared.BaseClasses.BaseMachine)

local MovementMachine = BaseMachine.new("Movement")

MovementMachine.States = {
	IdleState = require(script.Parent.States.Idle),
}

return MovementMachine
