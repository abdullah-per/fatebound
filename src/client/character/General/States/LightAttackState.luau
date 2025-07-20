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

-- These variables are now local to the module, as requested.
-- WARNING: This means they will be shared across ALL instances of LightAttackState,
-- which will likely cause incorrect behavior in a multi-player environment
-- as all players will share the same combo count and cooldown.
local lastAttackTime = 0
local comboCount = 0
local cooldownEndTime = 0

function LightAttackState.new()
	local self = setmetatable(BaseState.new("LightAttackState"), LightAttackState)
	return self
end

function LightAttackState:Enter(stateMachine)
	-- Safely get player configs, providing a default empty table if Controller or PlayerConfigs are nil
	local configs = stateMachine.Controller and stateMachine.Controller.PlayerConfigs or {}

	-- Define default values for configs if they are not set, using the safe 'configs' table
	local comboWindow = configs.LightAttackComboWindow or 0.2 -- Default to 0.3 seconds
	local maxCombo = configs.LightAttackMaxCombo or 2 -- Default to 3 attacks in a combo
	local detectionRange = configs.LightAttackDetectionRange or 8 -- Default to 8 studs
	local detectionSize = configs.LightAttackDetectionSize or Vector3.new(6, 6, 6) -- Default detection box size
	local attackDamage = configs.LightAttackDamage or 10 -- Default damage
	local attackCooldown = configs.LightAttackCooldown or 0.4 -- Default cooldown after max combo

	local currentTime = os.clock()

	-- Check if a cooldown is active using the module-level 'cooldownEndTime'
	if currentTime < cooldownEndTime then
		print(string.format("[LightAttackState] Attack on cooldown. Remaining: %.2f s", cooldownEndTime - currentTime))
		-- If on cooldown, immediately transition out of the attack state
		stateMachine:ChangeState(stateMachine.States.IdleState) -- Or appropriate movement state
		return
	end

	-- Update combo tracking using module-level 'lastAttackTime' and 'comboCount'
	local timeSinceLastAttack = currentTime - lastAttackTime

	if timeSinceLastAttack <= comboWindow then
		comboCount += 1
	else
		comboCount = 1 -- Start a new combo
	end

	-- Reset combo if it exceeds maximum using module-level 'comboCount'
	if comboCount > maxCombo then
		comboCount = 1 -- Start a new combo after max combo reached
	end

	lastAttackTime = currentTime -- Update module-level 'lastAttackTime'

	-- Slow the player
	self._originalWalkSpeed = stateMachine.Humanoid.WalkSpeed
	stateMachine.Humanoid.WalkSpeed = 6

	-- Play swing sound
	if stateMachine.SoundHandler then
		stateMachine.SoundHandler:Play("PunchSwing")
	end

	-- Play appropriate animation based on combo count
	local animName = `M{comboCount}` -- Use module-level 'comboCount'
	stateMachine.AnimationHandler:Play(animName)
	local animTrack = stateMachine.AnimationHandler.Tracks[animName]

	-- Ensure the connection is disconnected after use to prevent memory leaks
	local hitConnection
	hitConnection = animTrack:GetMarkerReachedSignal("HitEvent"):Connect(function()
		-- Detect enemies in range
		local characterRoot = stateMachine.Character.HumanoidRootPart
		local detectionPosition = characterRoot.CFrame * CFrame.new(0, 0, -detectionRange)
		local detectedParts = workspace:GetPartBoundsInBox(detectionPosition, detectionSize, overlapParams)
		local uniqueTargets = CombatUtils.getUniqueParentsFromParts(detectedParts)

		if #uniqueTargets > 0 then
			if stateMachine.SoundHandler then
				stateMachine.SoundHandler:Play("PunchHit")
			end
			-- Fire server event for damage and stun
			HitEvent:FireServer(attackDamage, uniqueTargets, "Soft")
		end
		-- Disconnect the signal after it fires once for this attack
		if hitConnection then
			hitConnection:Disconnect()
			hitConnection = nil
		end
	end)

	-- Wait for the animation to complete
	task.wait(animTrack.Length)

	-- Restore speed
	stateMachine.Humanoid.WalkSpeed = self._originalWalkSpeed or configs.WalkSpeed

	-- Apply cooldown if the max combo was just completed using module-level 'comboCount'
	if comboCount == maxCombo then
		cooldownEndTime = os.clock() + attackCooldown -- Update module-level 'cooldownEndTime'
		print(
			string.format("[LightAttackState] Max combo reached. Cooldown initiated for %.2f seconds.", attackCooldown)
		)
	end

	-- Transition to appropriate movement state based on input
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
