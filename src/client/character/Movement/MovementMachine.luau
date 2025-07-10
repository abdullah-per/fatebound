--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local CameraHandler = require(ReplicatedStorage.Shared.Utilities.CameraHandler)
local AnimationHandler = require(ReplicatedStorage.Shared.Utilities.AnimationHandler)
local BaseStateMachine = require(ReplicatedStorage.Shared.BaseClasses.BaseStateMachine)

--// Instances
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:WaitForChild("Humanoid")
local humanoidRP = character:WaitForChild("HumanoidRootPart")

--// Main
local MovementMachine = BaseStateMachine.new("MovementStateMachine")

MovementMachine.States = {
	IdleState = require(script.Parent.States.IdleState),
	WalkState = require(script.Parent.States.WalkState),
	RunState = require(script.Parent.States.RunState),
	DashState = require(script.Parent.States.DashState),
}

MovementMachine.DefaultState = MovementMachine.States.IdleState

-- movement configs
MovementMachine.Character = character
MovementMachine.Humanoid = humanoid
MovementMachine.HumanoidRP = humanoidRP

MovementMachine.WalkSpeed = 12
MovementMachine.RunSpeed = 22

MovementMachine.FrontDashDistance = 8
MovementMachine.SideDashDistance = 4
MovementMachine.BackDashDistance = 8

-- movement utils
MovementMachine.CameraHandler = CameraHandler.new()
MovementMachine.AnimationHandler = AnimationHandler.new(character, ReplicatedStorage.Assets.Players.Animations.Movement)

return MovementMachine
