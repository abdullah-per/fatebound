--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

--// Imports
local CameraHandler = require(ReplicatedStorage.Shared.Utilities.CameraHandler)
local AnimationHandler = require(ReplicatedStorage.Shared.Utilities.AnimationHandler)
local BaseStateMachine = require(ReplicatedStorage.Shared.BaseClasses.BaseStateMachine)
local SoundHandler = require(ReplicatedStorage.Shared.Utilities.SoundHandler)

--// Instances
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:WaitForChild("Humanoid")
local humanoidRP = character:WaitForChild("HumanoidRootPart")

--// Configs
local MovementMachine = BaseStateMachine.new("MovementStateMachine")

MovementMachine.States = {
	IdleState = require(script.Parent.States.IdleState),
	WalkState = require(script.Parent.States.WalkState),
	RunState = require(script.Parent.States.RunState),
	DashState = require(script.Parent.States.DashState),
	JumpState = require(script.Parent.States.JumpState),
}

MovementMachine.DefaultState = MovementMachine.States.IdleState

-- movement instances
MovementMachine.Character = character
MovementMachine.Humanoid = humanoid
MovementMachine.HumanoidRP = humanoidRP

-- movement utils
MovementMachine.CameraHandler = CameraHandler.new()
MovementMachine.AnimationHandler = AnimationHandler.new(character, ReplicatedStorage.Assets.Players.Animations.Movement)
MovementMachine.SoundHandler = SoundHandler.new(SoundService.Movement)

--// Update
function MovementMachine:DelegateUpdate(deltaTime)
	BaseStateMachine.DelegateUpdate(MovementMachine, deltaTime)

	if self.CurrentState ~= self.States.DashState then
		if self.Controller.PlayerConfigs.DashCharges <= 3 then
			self.Controller.PlayerConfigs.DashCharges += (self.Controller.PlayerConfigs.DashRechargeTime * deltaTime)
			self.Controller.PlayerConfigs.DashCharges =
				math.min(self.Controller.PlayerConfigs.DashCharges, self.Controller.PlayerConfigs.MaxDashCharges)
		end
	end

	print(self.Controller.PlayerConfigs.DashCharges)
end

return MovementMachine
