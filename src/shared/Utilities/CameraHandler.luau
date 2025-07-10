--// Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// Configs
local DASH_FOV = 70
local RUN_FOV = 65
local WALK_FOV = 60

--// Instances
local Camera = workspace.CurrentCamera

--// Main
local CameraHandler = {}
CameraHandler.__index = CameraHandler

function CameraHandler.new()
	local self = setmetatable({}, CameraHandler)
	self.Connections = {}
	return self
end

function CameraHandler:EnableLock()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false

	local connection1 = UserInputService.InputBegan:Connect(function(input, _gameProc)
		if _gameProc then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftAlt then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end
	end)

	local connection2 = UserInputService.InputEnded:Connect(function(input, _gameProc)
		if _gameProc then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftAlt then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
		end
	end)

	table.insert(self.Connections, connection1)
	table.insert(self.Connections, connection2)
end

function CameraHandler:DisableLock()
	for _, connection in self.Connections do
		connection:Disconnect()
	end
end

function CameraHandler:ChangeFOV(stateName)
	if stateName == "Dash" then
		local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine)
		local tween = TweenService:Create(Camera, tweenInfo, { FieldOfView = DASH_FOV })
		tween:Play()
	elseif stateName == "Run" then
		local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine)
		local tween = TweenService:Create(Camera, tweenInfo, { FieldOfView = RUN_FOV })
		tween:Play()
	elseif stateName == "Walk" or stateName == "Idle" then
		local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine)
		local tween = TweenService:Create(Camera, tweenInfo, { FieldOfView = WALK_FOV })
		tween:Play()
	end
end

return CameraHandler
