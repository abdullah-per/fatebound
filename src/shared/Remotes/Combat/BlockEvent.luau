--// Block RemoteEvent
-- This RemoteEvent is used to communicate block start/stop between client and server

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the RemoteEvent if it doesn't exist
local BlockEvent = Instance.new("RemoteEvent")
BlockEvent.Name = "BlockEvent"
BlockEvent.Parent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")

return BlockEvent
