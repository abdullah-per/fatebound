--// Services
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local Ragdoll = require(ReplicatedStorage.Shared.External.Ragdoll)

--// Main
local BackDash = {}

function BackDash.Enable(character)
	character.Archivable = true

	local clone = character:Clone()
	clone.Parent = workspace
	clone.Name = "RAGDOLL"
	local ragdoll = Ragdoll.EnableRagdoll(clone, Vector3.new(0, -1, 1), 7.5)

	local outline = ReplicatedStorage.Assets.VFX.WhiteOutline:Clone()
	outline.Name = "WhiteOutline"
	outline.Parent = character

	for _, part in character:GetChildren() do
		if (part:IsA("BasePart") or part:IsA("MeshPart")) and part.Name ~= "HumanoidRootPart" then
			part.Transparency = 0.5
		end
	end

	return ragdoll
end

local tweenInfo = TweenInfo.new(0.25)
function BackDash.Disable(character, ragdoll)
	-- setting seperate collision group
	for _, part in ragdoll:GetChildren() do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			part.CollisionGroup = "RagdollFloat"
		end
	end

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Parent = ragdoll.HumanoidRootPart
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.Attachment0 = ragdoll.HumanoidRootPart.RootAttachment

	while (character.HumanoidRootPart.Position - ragdoll.HumanoidRootPart.Position).Magnitude >= 3 do
		alignPosition.Position = character.HumanoidRootPart.Position
		alignPosition.Responsiveness += 1 -- increasing responsiveness the longer it goes...
		task.wait()
	end
	ragdoll:Destroy()

	-- removing outline
	task.spawn(function()
		if character.WhiteOutline then
			TweenService:Create(character.WhiteOutline, tweenInfo, { OutlineTransparency = 1 }):Play()
			task.wait(0.25)
			character.WhiteOutline:Destroy()
		end
	end)

	-- removing transparency from character
	task.spawn(function()
		for _, part in character:GetChildren() do
			if (part:IsA("BasePart") or part:IsA("MeshPart")) and part.Name ~= "HumanoidRootPart" then
				TweenService:Create(part, tweenInfo, { Transparency = 0 }):Play()
			end
		end
	end)

	return
end

return BackDash
