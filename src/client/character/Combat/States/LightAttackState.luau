--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local CombatUtils = require(ReplicatedStorage.Shared.Utilities.CombatUtils)

--// RemoteEvents
local HitEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("HitEvent")

--// Configuration
local ATTACK_COMBO_WINDOW = 1 -- seconds
local MAX_COMBO_COUNT = 4
local DETECTION_RANGE = 4 -- studs
local DETECTION_SIZE = Vector3.new(4, 4, 4)

--// Setup overlap parameters for hit detection
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.FilterDescendantsInstances =
	{ Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait() }

--// Main
local LightAttackState = BaseState.new("LightAttackState")

--// State variables
local lastAttackTime = 0
local comboCount = 0

function LightAttackState:Enter(stateMachine)
	-- Update combo tracking
	local currentTime = os.clock()
	local timeSinceLastAttack = currentTime - lastAttackTime

	if timeSinceLastAttack <= ATTACK_COMBO_WINDOW then
		comboCount += 1
	else
		comboCount = 1
	end

	-- Reset combo if it exceeds maximum
	if comboCount > MAX_COMBO_COUNT then
		comboCount = 1
	end

	-- Detect enemies in range
	local characterRoot = stateMachine.Character.HumanoidRootPart
	local detectionPosition = characterRoot.CFrame * CFrame.new(0, 0, -DETECTION_RANGE)

	local detectedParts = workspace:GetPartBoundsInBox(detectionPosition, DETECTION_SIZE, overlapParams)

	-- Get unique parent objects (characters) from detected parts
	local uniqueTargets = CombatUtils.getUniqueParentsFromParts(detectedParts)

	-- Send hit event to server if targets were detected
	if #uniqueTargets > 0 then
		HitEvent:FireServer("LightAttack", uniqueTargets)
	end

	-- Update attack timing and return to idle
	lastAttackTime = currentTime
	stateMachine:ChangeState(stateMachine.States.IdleState)
end

return LightAttackState
