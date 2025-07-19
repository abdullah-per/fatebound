--// Block Overload Visual RemoteEvent
-- This RemoteEvent is used to communicate block overload value updates to the client for UI

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the RemoteEvent if it doesn't exist
local BlockOverloadVisualEvent = Instance.new("RemoteEvent")
BlockOverloadVisualEvent.Name = "BlockOverloadVisualEvent"
BlockOverloadVisualEvent.Parent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")

return BlockOverloadVisualEvent
