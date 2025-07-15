--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseStateMachine = require(ReplicatedStorage.Shared.BaseClasses.BaseStateMachine)

--// Instances
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRP = character:WaitForChild("HumanoidRootPart")

--// Configs
local ClimbStateMachine = BaseStateMachine.new("ClimbStateMachine")

ClimbStateMachine.States = {
	WaitingState = require(script.Parent.States.ClimbWaitingState),
	IdleState = require(script.Parent.States.ClimbIdleState),
	MoveState = require(script.Parent.States.ClimbMoveState),
	JumpState = require(script.Parent.States.ClimbJumpState),
	DropState = require(script.Parent.States.ClimbDropState),
}

ClimbStateMachine.DefaultState = ClimbStateMachine.States.WaitingState

ClimbStateMachine.Character = character
ClimbStateMachine.Humanoid = humanoid
ClimbStateMachine.HumanoidRP = humanoidRP

return ClimbStateMachine
