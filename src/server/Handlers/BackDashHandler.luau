--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// RemoteEvents
local BackDashVisualEvent =
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Movement"):WaitForChild("BackDashVisualEvent")

--// BackDash Handler
local BackDashHandler = {}

--// Handle backdash events from clients
function BackDashHandler.HandleBackDashEvent(player)
	if not player or not player.Character then
		return
	end

	local character = player.Character
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then
		return
	end

	-- Only handle visual effects replication, let client handle mechanics
	BackDashVisualEvent:FireAllClients(player, "Enable")

	-- Wait for the backdash duration (client will handle the actual backdash)
	task.spawn(function()
		-- Match the client-side backdash duration
		task.wait(0.5) -- Adjust this to match your backdash duration

		-- Disable visual effects
		BackDashVisualEvent:FireAllClients(player, "Disable")
	end)
end

--// Initialize the backdash handler
function BackDashHandler.Init()
	local BackDashEvent =
		ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Movement"):WaitForChild("BackDashEvent")

	-- Connect to backdash events from clients
	BackDashEvent.OnServerEvent:Connect(function(player)
		BackDashHandler.HandleBackDashEvent(player)
	end)
end

return BackDashHandler
