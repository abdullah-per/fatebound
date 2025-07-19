--// InvincibilityEvent RemoteEvent Provider
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Define the path where the RemoteEvent should be created/found
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local combatFolder = remotesFolder:WaitForChild("Combat")

local EVENT_NAME = "InvincibilityEvent"
local InvincibilityEvent = combatFolder:FindFirstChild(EVENT_NAME)

-- If the RemoteEvent does not exist, create it.
if not InvincibilityEvent then
	InvincibilityEvent = Instance.new("RemoteEvent")
	InvincibilityEvent.Name = EVENT_NAME
	InvincibilityEvent.Parent = combatFolder
	print(string.format("[InvincibilityEvent Module] Created new RemoteEvent: %s", EVENT_NAME))
else
	print(string.format("[InvincibilityEvent Module] Found existing RemoteEvent: %s", EVENT_NAME))
end

return InvincibilityEvent
