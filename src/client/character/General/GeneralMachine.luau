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
local GeneralStateMachine = BaseStateMachine.new("GeneralStateMachine")

GeneralStateMachine.States = {
	IdleState = require(script.Parent.States.IdleState),
	WalkState = require(script.Parent.States.WalkState),
	RunState = require(script.Parent.States.RunState),
	DashState = require(script.Parent.States.DashState),
	JumpState = require(script.Parent.States.JumpState),
	BlockState = require(script.Parent.States.BlockState),
	LightAttackState = require(script.Parent.States.LightAttackState),
	HeavyAttackState = require(script.Parent.States.HeavyAttackState),
}

GeneralStateMachine.DefaultState = GeneralStateMachine.States.IdleState

-- movement instances
GeneralStateMachine.Character = character
GeneralStateMachine.Humanoid = humanoid
GeneralStateMachine.HumanoidRP = humanoidRP

-- movement utils
GeneralStateMachine.CameraHandler = CameraHandler.new()
GeneralStateMachine.AnimationHandler =
	AnimationHandler.new(character, ReplicatedStorage.Assets.Players.Animations.General)
GeneralStateMachine.SoundHandler = SoundHandler.new(SoundService.General)

--// Configurations
GeneralStateMachine.Controller = GeneralStateMachine.Controller or {}
GeneralStateMachine.Controller.PlayerConfigs = GeneralStateMachine.Controller.PlayerConfigs or {}
GeneralStateMachine.Controller.PlayerConfigs.BlockWalkSpeed = 8 -- Default block walk speed, can be changed

--// Update
function GeneralStateMachine:DelegateUpdate(deltaTime)
	BaseStateMachine.DelegateUpdate(GeneralStateMachine, deltaTime)

	if self.CurrentState ~= self.States.DashState then
		if self.Controller.PlayerConfigs.DashCharges <= 3 then
			self.Controller.PlayerConfigs.DashCharges += (self.Controller.PlayerConfigs.DashRechargeTime * deltaTime)
			self.Controller.PlayerConfigs.DashCharges =
				math.min(self.Controller.PlayerConfigs.DashCharges, self.Controller.PlayerConfigs.MaxDashCharges)
		end
	end
end

return GeneralStateMachine
