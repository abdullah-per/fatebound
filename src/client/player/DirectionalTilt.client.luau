local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local RootJoint = RootPart:WaitForChild("RootJoint")
local RootC0 = RootJoint.C0

local MaxTiltAngle = 3

local Tilt = CFrame.new()
RunService.RenderStepped:Connect(function(Delta)
	local MoveDirection = RootPart.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
	Tilt = Tilt:Lerp(
		CFrame.Angles(math.rad(-MoveDirection.Z) * MaxTiltAngle, math.rad(-MoveDirection.X) * MaxTiltAngle, 0),
		0.2 ^ (1 / (Delta * 60))
	)
	RootJoint.C0 = RootC0 * Tilt
end)
