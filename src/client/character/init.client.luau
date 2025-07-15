--// Client Initialization
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local Controller = require(ReplicatedStorage.Shared.Controller.StateMachineController)
local MovementMachine = require(script.General.GeneralMachine)
local BackDashVisualHandler = require(script.BackDashVisualHandler)
local ClimbStateMachine = require(script.Climb.ClimbStateMachine)

--// Remotes
local PlayerConfigEvent = ReplicatedStorage:WaitForChild("PlayerConfigEvent")

--// Setup controller
Controller.PlayerConfigs = {}
setmetatable(Controller, { __index = Controller })

-- Listen for config from server
PlayerConfigEvent.OnClientEvent:Connect(function(config)
	Controller.PlayerConfigs = config
end)

-- Request config from server on join (in case of missed event)
PlayerConfigEvent:FireServer()

--// Setup machines
local controller = Controller.new(MovementMachine)

--// Enable machines
controller:EnableAllStates()

--// Initialize backdash visual handler
BackDashVisualHandler.Init()
