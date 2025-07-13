--// Combat Hit RemoteEvent
-- This RemoteEvent is used to communicate hit detection between client and server

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the RemoteEvent if it doesn't exist
local HitEvent = Instance.new("RemoteEvent")
HitEvent.Name = "HitEvent"
HitEvent.Parent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")

return HitEvent
