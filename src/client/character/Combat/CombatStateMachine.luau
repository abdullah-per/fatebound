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
local CombatMachine = BaseStateMachine.new("MovementStateMachine")

CombatMachine.States = {
	IdleState = require(script.Parent.States.IdleState),
	BlockState = require(script.Parent.States.BlockState),
	LightAttackState = require(script.Parent.States.LightAttackState),
	HeavyAttackState = require(script.Parent.States.HeavyAttackState),
}

CombatMachine.DefaultState = CombatMachine.States.IdleState

-- movement instances
CombatMachine.Character = character
CombatMachine.HumanoidRP = humanoidRP

-- movement utils
CombatMachine.SoundHandler = SoundHandler.new(SoundService.Movement)
CombatMachine.AnimationHandler = AnimationHandler.new(character, ReplicatedStorage.Assets.Players.Animations.Movement)

return CombatMachine
