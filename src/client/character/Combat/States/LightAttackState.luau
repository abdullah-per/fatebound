--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Imports
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local CombatUtils = require(ReplicatedStorage.Shared.Utilities.CombatUtils)

--// RemoteEvents
local HitEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("HitEvent")

--// Setup overlap parameters for hit detection
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.FilterDescendantsInstances =
	{ Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait() }

--// Main
local LightAttackState = {}
LightAttackState.__index = LightAttackState
setmetatable(LightAttackState, { __index = BaseState })

function LightAttackState.new()
	local self = setmetatable(BaseState.new("LightAttackState"), LightAttackState)
	self.lastAttackTime = 0
	self.comboCount = 0
	return self
end

function LightAttackState:Enter(stateMachine)
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
		print("[LightAttack] Disabling movement state machine for attack")
		stateMachine.Controller:SetStateMachineEnabled(movementMachine, false)
	end

	-- Update combo tracking
	local currentTime = os.clock()
	local timeSinceLastAttack = currentTime - self.lastAttackTime

	if timeSinceLastAttack <= configs.LightAttackComboWindow then
		self.comboCount += 1
	else
		self.comboCount = 1
	end

	-- Reset combo if it exceeds maximum
	if self.comboCount > configs.LightAttackMaxCombo then
		self.comboCount = 1
	end

	-- Detect enemies in range
	local characterRoot = stateMachine.Character.HumanoidRootPart
	local detectionPosition = characterRoot.CFrame * CFrame.new(0, 0, -configs.LightAttackDetectionRange)

	local detectedParts =
		workspace:GetPartBoundsInBox(detectionPosition, configs.LightAttackDetectionSize, overlapParams)

	-- Get unique parent objects (characters) from detected parts
	local uniqueTargets = CombatUtils.getUniqueParentsFromParts(detectedParts)

	-- Send hit event to server if targets were detected
	if #uniqueTargets > 0 then
		HitEvent:FireServer("LightAttack", uniqueTargets)
	end

	-- Effects
	print("[LightAttack] Playing animation: M" .. tostring(self.comboCount))
	stateMachine.AnimationHandler:Play(`M{self.comboCount}`)
	task.wait(stateMachine.AnimationHandler.Tracks[`M{self.comboCount}`].Length)
	print("[LightAttack] Animation finished, re-enabling movement state machine")

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

return LightAttackState
