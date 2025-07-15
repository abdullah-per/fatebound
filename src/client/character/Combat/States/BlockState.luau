--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Main
local BlockState = {}
BlockState.__index = BlockState
setmetatable(BlockState, { __index = BaseState })

function BlockState.new()
	local self = setmetatable(BaseState.new("BlockState"), BlockState)
	return self
end

function BlockState:Enter(stateMachine)
	stateMachine.AnimationHandler:Play("Block")
	-- Disable movement state machine except for slow walk
	local movementMachine = nil
	for _, machine in ipairs(stateMachine.Controller.StateMachines or {}) do
		if machine.Name == "MovementStateMachine" then
			movementMachine = machine
			break
		end
	end
	if stateMachine.Controller and stateMachine.Controller.SetStateMachineEnabled and movementMachine then
		stateMachine.Controller:SetStateMachineEnabled(movementMachine, false)
		if movementMachine.Humanoid then
			movementMachine.Humanoid.WalkSpeed = 8
		end
	end
end

function BlockState:HandleInput(stateMachine, input, eventType)
	if input.KeyCode == Enum.KeyCode.F and eventType == "ended" then
		-- Re-enable movement state machine
		local movementMachine = nil
		for _, machine in ipairs(stateMachine.Controller.StateMachines or {}) do
			if machine.Name == "MovementStateMachine" then
				movementMachine = machine
				break
			end
		end
		if stateMachine.Controller and stateMachine.Controller.SetStateMachineEnabled and movementMachine then
			stateMachine.Controller:SetStateMachineEnabled(movementMachine, true)
		end
		stateMachine:ChangeState(stateMachine.States.IdleState)
	end
end

function BlockState:Update(stateMachine, delta)
	stateMachine.Humanoid.WalkSpeed = 8
end

return BlockState
