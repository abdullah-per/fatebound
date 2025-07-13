--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local CombatUtils = require(ReplicatedStorage.Shared.Utilities.CombatUtils)

--// RemoteEvents
local HitEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("HitEvent")

--// Configuration
local DETECTION_RANGE = 4 -- studs
local DETECTION_SIZE = Vector3.new(4, 4, 4)

--// Setup overlap parameters for hit detection
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.FilterDescendantsInstances =
	{ Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait() }

--// Main
local HeavyAttackState = BaseState.new("HeavyAttackState")

function HeavyAttackState:Enter(stateMachine)
	-- Detect enemies in range
	local characterRoot = stateMachine.Character.HumanoidRootPart
	local detectionPosition = characterRoot.CFrame * CFrame.new(0, 0, -DETECTION_RANGE)

	local detectedParts = workspace:GetPartBoundsInBox(detectionPosition, DETECTION_SIZE, overlapParams)

	-- Get unique parent objects (characters) from detected parts
	local uniqueTargets = CombatUtils.getUniqueParentsFromParts(detectedParts)

	-- Send hit event to server if targets were detected
	if #uniqueTargets > 0 then
		HitEvent:FireServer("HeavyAttack", uniqueTargets)
	end

	-- Return to idle state immediately
	stateMachine:ChangeState(stateMachine.States.IdleState)
end

function HeavyAttackState:HandleInput(stateMachine, input, eventType) end

function HeavyAttackState:Update(stateMachine, deltaTime) end

return HeavyAttackState
