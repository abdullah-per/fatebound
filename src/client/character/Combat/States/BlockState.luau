--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// Main
local BlockState = BaseState.new("BlockState")

function BlockState:Enter(stateMachine)
	-- stateMachine.AnimationHandler:Play("Idle")
end

function BlockState:HandleInput(stateMachine, input, eventType) end

function BlockState:Update(stateMachine, deltaTime) end

return BlockState
