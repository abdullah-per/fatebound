--// BackDash RemoteEvent
-- This RemoteEvent is used to communicate backdash actions between client and server

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the RemoteEvent if it doesn't exist
local BackDashEvent = Instance.new("RemoteEvent")
BackDashEvent.Name = "BackDashEvent"
BackDashEvent.Parent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Movement")

return BackDashEvent
