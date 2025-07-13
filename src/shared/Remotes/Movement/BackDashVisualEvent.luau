--// BackDash Visual Effects RemoteEvent
-- This RemoteEvent is used to replicate backdash visual effects to all clients

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the RemoteEvent if it doesn't exist
local BackDashVisualEvent = Instance.new("RemoteEvent")
BackDashVisualEvent.Name = "BackDashVisualEvent"
BackDashVisualEvent.Parent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Movement")

return BackDashVisualEvent
