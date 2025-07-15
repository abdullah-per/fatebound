local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:FindFirstChild("PlayerConfigEvent")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "PlayerConfigEvent"
	remote.Parent = ReplicatedStorage
end

return remote
