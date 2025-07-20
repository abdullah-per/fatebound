--// Client Initialization
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local Controller = require(ReplicatedStorage.Shared.Controller.StateMachineController)
local MovementMachine = require(script.General.GeneralMachine)
local ClimbStateMachine = require(script.Climb.ClimbStateMachine)
local GeneralMachine = require(script.General.GeneralMachine)

--// Remotes
local PlayerConfigEvent = ReplicatedStorage:WaitForChild("PlayerConfigEvent")

--// Setup controller
Controller.PlayerConfigs = {}

-- Listen for config from server
PlayerConfigEvent.OnClientEvent:Connect(function(config)
	Controller.PlayerConfigs = config
end)

-- Request config from server on join (in case of missed event)
PlayerConfigEvent:FireServer()

--// Setup machines
local controller = Controller.new(MovementMachine, ClimbStateMachine)
controller.MovementMachine = MovementMachine
controller.ClimbStateMachine = ClimbStateMachine

--// Enable machines
controller:EnableAllStates()

--// Initialize backdash visual handler
local BackDashVisualHandler = require(script.VisualHandlers.BackDashVisualHandler)
BackDashVisualHandler.Init()

-- Initialize block bar UI handler
local BlockBarHandler = require(script.VisualHandlers.BlockBarHandler)
BlockBarHandler.Init()

-- Initialize health bar UI handler
local HealthBarHandler = require(script.VisualHandlers.HealthBarHandler)
HealthBarHandler.Init(MovementMachine.Humanoid)

-- Initialize dash bar UI handler
local DashBarHandler = require(script.VisualHandlers.DashBarHandler)
DashBarHandler.Init(MovementMachine)

-- Stun
local StunEvent = require(ReplicatedStorage.Shared.Remotes.Combat.StunEvent)
StunEvent.OnClientEvent:Connect(function(stunType, duration)
	GeneralMachine:ChangeState(GeneralMachine.States.IdleState)
	GeneralMachine:Disable()
	task.wait(duration)
	GeneralMachine:Enable()
end)
