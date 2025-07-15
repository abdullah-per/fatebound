--// Server Initialization
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Initialize combat system
local CombatHandler = require(script.Handlers.CombatHandler)
CombatHandler.Init()

--// Initialize backdash system
local BackDashHandler = require(script.Handlers.BackDashHandler)
BackDashHandler.Init()

-- Initialize player config system
local PlayerConfigHandler = require(script.Handlers.PlayerConfigHandler)
task.spawn(function()
	PlayerConfigHandler:StartPeriodicResend()
end)
