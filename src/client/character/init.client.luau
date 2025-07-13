--// Client Initialization
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local Controller = require(ReplicatedStorage.Shared.Controller.StateMachineController)
local MovementMachine = require(script.Movement.MovementMachine)
local CombatMachine = require(script.Combat.CombatStateMachine)
local BackDashVisualHandler = require(script.BackDashVisualHandler)

--// Initialize character systems
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

--// Setup controller
Controller.PlayerConfigs = {
	WalkSpeed = 16,
	RunSpeed = 24,
	DashCharges = 3,
	MaxDashCharges = 3,
	DashRechargeTime = 1,
	DashDuration = 0.4,
	SideDashDistance = 6,
	FrontDashDistance = 10,
	BackDashDistance = 8,
}

--// Setup machines
MovementMachine.Controller = Controller
CombatMachine.Controller = Controller

--// Enable machines
MovementMachine:Enable()
CombatMachine:Enable()

--// Initialize backdash visual handler
BackDashVisualHandler.Init()
