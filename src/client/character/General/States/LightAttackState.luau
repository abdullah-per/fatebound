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

	-- Update combo tracking
	local currentTime = os.clock()
	local timeSinceLastAttack = currentTime - (self.lastAttackTime or 0)

	if timeSinceLastAttack <= configs.LightAttackComboWindow then
		self.comboCount += 1
	else
		self.comboCount = 1
	end

	-- Reset combo if it exceeds maximum
	if self.comboCount > configs.LightAttackMaxCombo then
		self.comboCount = 1
	end

	self.lastAttackTime = currentTime

	-- Slow the player
	self._originalWalkSpeed = stateMachine.Humanoid.WalkSpeed
	stateMachine.Humanoid.WalkSpeed = 6

	-- Play swing sound
	if stateMachine.SoundHandler then
		stateMachine.SoundHandler:Play("PunchSwing")
	end

	stateMachine.AnimationHandler:Play(`M{self.comboCount}`)
	local animTrack = stateMachine.AnimationHandler.Tracks[`M{self.comboCount}`]
	local animLength = animTrack and animTrack.Length or 0.5

	-- Temporary delay before hit detection for realism
	task.wait(0.15)

	-- Detect enemies in range
	local characterRoot = stateMachine.Character.HumanoidRootPart
	local detectionPosition = characterRoot.CFrame * CFrame.new(0, 0, -configs.LightAttackDetectionRange)
	local detectedParts =
		workspace:GetPartBoundsInBox(detectionPosition, configs.LightAttackDetectionSize, overlapParams)
	local uniqueTargets = CombatUtils.getUniqueParentsFromParts(detectedParts)

	if #uniqueTargets > 0 then
		if stateMachine.SoundHandler then
			stateMachine.SoundHandler:Play("PunchHit")
		end
		HitEvent:FireServer(configs.LightAttackDamage, uniqueTargets, "Soft")
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

return LightAttackState
