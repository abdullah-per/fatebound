--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

--// RemoteEvents
local BackDashVisualEvent =
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Movement"):WaitForChild("BackDashVisualEvent")

--// BackDash Visual Handler
local BackDashVisualHandler = {}

--// Apply visual effects to a character
function BackDashVisualHandler.ApplyVisualEffects(character, enable)
	if not character then
		return
	end

	-- Don't apply effects to local player (they get effects from client-side backdash)
	local localPlayer = Players.LocalPlayer
	if character == localPlayer.Character then
		return
	end

	if enable then
		-- Add outline
		local outline = ReplicatedStorage.Assets.VFX.WhiteOutline:Clone()
		outline.Name = "WhiteOutline"
		outline.Parent = character

		-- Apply transparency to parts
		for _, part in character:GetChildren() do
			if (part:IsA("BasePart") or part:IsA("MeshPart")) and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 0.5
			end
		end
	else
		-- Remove outline with tween
		if character.WhiteOutline then
			local tweenInfo = TweenInfo.new(0.25)
			TweenService:Create(character.WhiteOutline, tweenInfo, { OutlineTransparency = 1 }):Play()
			task.wait(0.25)
			character.WhiteOutline:Destroy()
		end

		-- Remove transparency with tween
		local tweenInfo = TweenInfo.new(0.25)
		for _, part in character:GetChildren() do
			if (part:IsA("BasePart") or part:IsA("MeshPart")) and part.Name ~= "HumanoidRootPart" then
				TweenService:Create(part, tweenInfo, { Transparency = 0 }):Play()
			end
		end
	end
end

--// Initialize the visual handler
function BackDashVisualHandler.Init()
	-- Connect to visual effects events from server
	BackDashVisualEvent.OnClientEvent:Connect(function(player, action)
		if player and player.Character then
			BackDashVisualHandler.ApplyVisualEffects(player.Character, action == "Enable")
		end
	end)
end

return BackDashVisualHandler
