--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local Wind = require(ReplicatedStorage.Shared.External.Wind)
local MovementMachine = require(script.Movement.MovementMachine)
local StateMachineController = require(ReplicatedStorage.Shared.Controller.StateMachineController)

--// Main
local Controller = StateMachineController.new(MovementMachine)
Controller:EnableAllStates()

local WindEffect = Wind.new({
	Location = game.Workspace.Camera,
	Randomized = false,
	Velocity = Vector3.new(0.45, 0, 0),
	Amount = 20,
	Current = 0,
	Frequency = 0.5,
	Lifetime = 2,
	Amplitude = 0.15,
	Range = 200,
	Part = ReplicatedStorage.Assets.VFX.Wind,
	Time = nil,
})
WindEffect:Start()
