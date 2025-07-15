--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local CombatUtils = require(ReplicatedStorage.Shared.Utilities.CombatUtils)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// RemoteEvents
local HitEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("HitEvent")

--// Setup overlap parameters for hit detection
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.FilterDescendantsInstances =
	{ Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait() }

--// Main
local HeavyAttackState = {}
HeavyAttackState.__index = HeavyAttackState
setmetatable(HeavyAttackState, { __index = BaseState })

function HeavyAttackState.new()
	local self = setmetatable(BaseState.new("HeavyAttackState"), HeavyAttackState)
	return self
end

function HeavyAttackState:Enter(stateMachine)
	local configs = stateMachine.Controller.PlayerConfigs

	-- Slow the player
	self._originalWalkSpeed = stateMachine.Humanoid.WalkSpeed
	stateMachine.Humanoid.WalkSpeed = 2

	stateMachine.AnimationHandler:Play("HeavyAttack")
	local animTrack = stateMachine.AnimationHandler.Tracks.HeavyAttack
	local animLength = animTrack and animTrack.Length or 0.5

	-- Temporary delay before hit detection for realism
	task.wait(0.15)

	-- Detect enemies in range
	local characterRoot = stateMachine.Character.HumanoidRootPart
	local detectionPosition = characterRoot.CFrame * CFrame.new(0, 0, -configs.HeavyAttackDetectionRange)
	local detectedParts =
		workspace:GetPartBoundsInBox(detectionPosition, configs.HeavyAttackDetectionSize, overlapParams)
	local uniqueTargets = CombatUtils.getUniqueParentsFromParts(detectedParts)

	if #uniqueTargets > 0 then
		HitEvent:FireServer("HeavyAttack", uniqueTargets)
	end

	-- Wait for animation to finish
	task.wait(animLength - 0.15)

	-- Restore speed
	stateMachine.Humanoid.WalkSpeed = self._originalWalkSpeed or configs.WalkSpeed

	if InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
		if
			stateMachine.PreviousState == stateMachine.States.RunState
			or stateMachine.BeforePreviousState == stateMachine.States.RunState
		then
			stateMachine:ChangeState(stateMachine.States.RunState)
		else
			stateMachine:ChangeState(stateMachine.States.WalkState)
		end
	else
		stateMachine:ChangeState(stateMachine.States.IdleState)
	end
end

return HeavyAttackState
