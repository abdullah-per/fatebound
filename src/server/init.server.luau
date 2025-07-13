--// Server Initialization
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Initialize combat system
local CombatHandler = require(script.Handlers.CombatHandler)
CombatHandler.Init()

--// Initialize backdash system
local BackDashHandler = require(script.Handlers.BackDashHandler)
BackDashHandler.Init()
