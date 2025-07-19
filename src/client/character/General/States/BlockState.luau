--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)
local BlockEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("BlockEvent")

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
	stateMachine.Humanoid.WalkSpeed = stateMachine.Controller.PlayerConfigs.BlockWalkSpeed or 8
	BlockEvent:FireServer("Start")
end

function BlockState:Exit(stateMachine)
	BlockEvent:FireServer("Stop")
end

function BlockState:HandleInput(stateMachine, input, eventType)
	if input.KeyCode == Enum.KeyCode.F and eventType == "ended" then
		if InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
			if
				stateMachine.PreviousState == stateMachine.States.RunState
				or stateMachine.BeforePreviousState == stateMachine.States.RunState
			then
				stateMachine:ChangeState(stateMachine.States.RunState)
			else
				stateMachine:ChangeState(stateMachine.States.WalkState)
			end
		else
			stateMachine:ChangeState(stateMachine.States.IdleState)
		end
	end
end

return BlockState
