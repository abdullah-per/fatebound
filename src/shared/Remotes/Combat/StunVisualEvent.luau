--// StunVisualEvent RemoteEvent Provider
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Define the path where the RemoteEvent should be created/found
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local combatFolder = remotesFolder:WaitForChild("Combat")

local EVENT_NAME = "StunVisualEvent"
local StunVisualEvent = combatFolder:FindFirstChild(EVENT_NAME)

-- If the RemoteEvent does not exist, create it.
if not StunVisualEvent then
	StunVisualEvent = Instance.new("RemoteEvent")
	StunVisualEvent.Name = EVENT_NAME
	StunVisualEvent.Parent = combatFolder
	print(string.format("[StunVisualEvent Module] Created new RemoteEvent: %s", EVENT_NAME))
else
	print(string.format("[StunVisualEvent Module] Found existing RemoteEvent: %s", EVENT_NAME))
end

return StunVisualEvent
