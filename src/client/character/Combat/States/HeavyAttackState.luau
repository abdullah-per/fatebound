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
local HeavyAttackState = {}
HeavyAttackState.__index = HeavyAttackState
setmetatable(HeavyAttackState, { __index = BaseState })

function HeavyAttackState.new()
	local self = setmetatable(BaseState.new("HeavyAttackState"), HeavyAttackState)
	return self
end

function HeavyAttackState:Enter(stateMachine)
	local configs = stateMachine.Controller.PlayerConfigs
	-- Find MovementMachine from controller's StateMachines
	local movementMachine = nil
	for _, machine in ipairs(stateMachine.Controller.StateMachines or {}) do
		if machine.Name == "MovementStateMachine" then
			movementMachine = machine
			break
		end
	end
	-- Disable movement state machine
	if stateMachine.Controller and stateMachine.Controller.SetStateMachineEnabled and movementMachine then
		print("[HeavyAttack] Disabling movement state machine for attack")
		stateMachine.Controller:SetStateMachineEnabled(movementMachine, false)
	end
	-- Detect enemies in range
	local characterRoot = stateMachine.Character.HumanoidRootPart
	local detectionPosition = characterRoot.CFrame * CFrame.new(0, 0, -configs.HeavyAttackDetectionRange)

	local detectedParts =
		workspace:GetPartBoundsInBox(detectionPosition, configs.HeavyAttackDetectionSize, overlapParams)

	-- Get unique parent objects (characters) from detected parts
	local uniqueTargets = CombatUtils.getUniqueParentsFromParts(detectedParts)

	-- Send hit event to server if targets were detected
	if #uniqueTargets > 0 then
		HitEvent:FireServer("HeavyAttack", uniqueTargets)
	end

	-- Effects
	print("[HeavyAttack] Playing animation: HeavyAttack")
	stateMachine.AnimationHandler:Play("HeavyAttack")
	task.wait(stateMachine.AnimationHandler.Tracks.HeavyAttack.Length)
	print("[HeavyAttack] Animation finished, re-enabling movement state machine")

	if stateMachine.Controller and stateMachine.Controller.SetStateMachineEnabled and movementMachine then
		stateMachine.Controller:SetStateMachineEnabled(movementMachine, true)
		local InputHandler = require(game:GetService("ReplicatedStorage").Shared.Utilities.InputHandler)
		if InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
			if
				movementMachine.PreviousState == movementMachine.States.RunState
				or movementMachine.BeforePreviousState == movementMachine.States.RunState
			then
				movementMachine:ChangeState(movementMachine.States.RunState)
			else
				movementMachine:ChangeState(movementMachine.States.WalkState)
			end
		else
			movementMachine:ChangeState(movementMachine.States.IdleState)
		end
	end
	stateMachine:ChangeState(stateMachine.States.IdleState)
end

function HeavyAttackState:HandleInput(stateMachine, input, eventType) end

function HeavyAttackState:Update(stateMachine, deltaTime) end

return HeavyAttackState
