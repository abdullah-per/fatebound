--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--// Imports
local Spring = require(ReplicatedStorage.Shared.External.Spring)
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local BackDash = require(ReplicatedStorage.Shared.Movement.BackDash)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

--// RemoteEvents
local BackDashEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Movement"):WaitForChild("BackDashEvent")
-- ASSUMPTION: InvincibilityEvent is located in ReplicatedStorage.Remotes.Combat
local InvincibilityEvent =
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("InvincibilityEvent")

--// Configs
local CURRENT_GHOST_TIME = 0 -- Global for ghost time, as per original

--// Instances
local DashSpring = Spring.create(Spring, 7)

--// Nearest Target
function FindNearestTarget(stateMachine, maxDistance, coneAngle)
	local playerCharacter = stateMachine.Character
	local playerHumanoidRP = stateMachine.HumanoidRP
	local playerLookVector = playerHumanoidRP.CFrame.lookVector

	local nearestTarget = nil
	local shortestDistance = math.huge

	local maxDotProduct = math.cos(math.rad(coneAngle / 2))

	-- Search for other players
	for _, player in ipairs(Players:GetPlayers()) do
		local targetCharacter = player.Character
		if targetCharacter and targetCharacter ~= playerCharacter then
			local targetHumanoidRP = targetCharacter:FindFirstChild("HumanoidRootPart")
			if targetHumanoidRP and targetCharacter:FindFirstChildOfClass("Humanoid") then
				local distance = (targetHumanoidRP.Position - playerHumanoidRP.Position).Magnitude
				if distance <= maxDistance then
					local directionToTarget = (targetHumanoidRP.Position - playerHumanoidRP.Position).Unit
					local dotProduct = playerLookVector:Dot(directionToTarget)

					if dotProduct >= maxDotProduct then
						if distance < shortestDistance then
							shortestDistance = distance
							nearestTarget = targetHumanoidRP
						end
					end
				end
			end
		end
	end

	-- Search for NPCs tagged as "AttackableNPC"
	for _, child in ipairs(Workspace:GetChildren()) do
		if CollectionService:HasTag(child, "AttackableNPC") and child:IsA("Model") then
			local targetHumanoidRP = child:FindFirstChild("HumanoidRootPart")
			if targetHumanoidRP and child:FindFirstChildOfClass("Humanoid") then
				local distance = (targetHumanoidRP.Position - playerHumanoidRP.Position).Magnitude
				if distance <= maxDistance then
					local directionToTarget = (targetHumanoidRP.Position - playerHumanoidRP.Position).Unit
					local dotProduct = playerLookVector:Dot(directionToTarget)

					if dotProduct >= maxDotProduct then
						if distance < shortestDistance then
							shortestDistance = distance
							nearestTarget = targetHumanoidRP
						end
					end
				end
			end
		end
	end

	return nearestTarget
end

--// Main
local DashState = {}
DashState.__index = DashState
setmetatable(DashState, { __index = BaseState })

function DashState.new()
	local self = setmetatable(BaseState.new("DashState"), DashState)
	self.Target = nil
	return self
end

local waitForGhost = false
local accumulatedTime = 0
local isBackDashing = false

-- Helper function to handle the logic for initiating a dash
function DashState:HandleDashInput(stateMachine)
	local playerConfigs = stateMachine.Controller.PlayerConfigs
	local dashInitiated = false

	-- Reset state variables for a new dash attempt
	accumulatedTime = 0
	self.Target = nil

	-- Spring reset: Crucial for ensuring each dash starts from a clean spring state.
	-- This sequence zeroes out the spring's position and velocity.
	DashSpring.Position = Vector3.new()
	DashSpring.Velocity = Vector3.new()
	DashSpring.Target = Vector3.new()

	if InputHandler.AllPressed(Enum.KeyCode.S) and playerConfigs.DashCharges >= 3 then -- back dash
		dashInitiated = true
		local combatMachine = nil
		for _, machine in ipairs(stateMachine.Controller.StateMachines or {}) do
			if machine.Name == "CombatStateMachine" then
				combatMachine = machine
				break
			end
		end

		if stateMachine.Controller and stateMachine.Controller.SetStateMachineEnabled and combatMachine then
			stateMachine.Controller:SetStateMachineEnabled(combatMachine, false)
		end
		stateMachine.AnimationHandler:Play("Dash_Back")
		stateMachine.CameraHandler:ChangeFOV("Dash")

		playerConfigs.DashCharges = 0

		-- Play ghost idle animation after back dash animation
		task.spawn(function()
			task.wait(stateMachine.AnimationHandler.Tracks.Dash_Back.Length + 0.1)
			stateMachine.AnimationHandler:Play("Ghost_Idle")
		end)

		stateMachine.SoundHandler:Play("Dash_Back")
		DashSpring.shove(DashSpring, Vector3.new(0, 0, playerConfigs.BackDashDistance))

		CURRENT_GHOST_TIME = stateMachine.SoundHandler.Tracks.Dash_Back.TimeLength
		stateMachine.Humanoid.WalkSpeed = 30

		waitForGhost = true
		isBackDashing = true

		InvincibilityEvent:FireServer(CURRENT_GHOST_TIME, "BackDash")

		local ragdoll = BackDash.Enable(stateMachine.Character)
		task.wait(CURRENT_GHOST_TIME)
		BackDash.Disable(stateMachine.Character, ragdoll)

		waitForGhost = false
		isBackDashing = false

		stateMachine.Humanoid.WalkSpeed = playerConfigs.WalkSpeed

		BackDashEvent:FireServer()

		-- Re-enable combat machine after back dash sequence
		task.spawn(function()
			task.wait(stateMachine.AnimationHandler.Tracks.Dash_Back.Length + 0.1)
			if stateMachine.Controller and stateMachine.Controller.SetStateMachineEnabled and combatMachine then
				stateMachine.Controller:SetStateMachineEnabled(combatMachine, true)
			end
		end)
	elseif InputHandler.AllPressed(Enum.KeyCode.A) and playerConfigs.DashCharges >= 1 then -- left dash
		dashInitiated = true
		stateMachine.AnimationHandler:Play("Dash_Left")
		stateMachine.SoundHandler:Play("Dash_Side")
		stateMachine.CameraHandler:ChangeFOV("Dash")

		playerConfigs.DashCharges -= 1
		DashSpring.shove(DashSpring, Vector3.new(-playerConfigs.SideDashDistance, 0, 0))
		InvincibilityEvent:FireServer(playerConfigs.DashDuration, "LeftDash")
	elseif InputHandler.AllPressed(Enum.KeyCode.D) and playerConfigs.DashCharges >= 1 then -- right dash
		dashInitiated = true
		stateMachine.AnimationHandler:Play("Dash_Right")
		stateMachine.SoundHandler:Play("Dash_Side")
		stateMachine.CameraHandler:ChangeFOV("Dash")

		playerConfigs.DashCharges -= 1
		DashSpring.shove(DashSpring, Vector3.new(playerConfigs.SideDashDistance, 0, 0))
		InvincibilityEvent:FireServer(playerConfigs.DashDuration, "RightDash")
	elseif
		not InputHandler.AnyPressed(Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D)
		and playerConfigs.DashCharges >= 2
	then
		-- auto lock / front dash
		dashInitiated = true
		local nearestTarget = FindNearestTarget(stateMachine, playerConfigs.FrontDashMaxDistance, 90)

		if nearestTarget then
			self.Target = nearestTarget
			local directionToTarget = (self.Target.Position - stateMachine.HumanoidRP.Position)
			-- For auto-lock, calculate the dash magnitude to reach the target's position.
			-- This ensures the dash covers the full distance to the target within the max distance.
			local dashMagnitude = directionToTarget.Magnitude

			local localDirectionToTarget = stateMachine.HumanoidRP.CFrame:VectorToObjectSpace(directionToTarget.Unit)
			DashSpring.shove(DashSpring, localDirectionToTarget * dashMagnitude)

			print("Auto-locking onto: ", self.Target.Parent.Name, " - Dash magnitude:", dashMagnitude)
			InvincibilityEvent:FireServer(playerConfigs.DashDuration, "AutoLockDash")
		else
			self.Target = nil
			DashSpring.shove(DashSpring, Vector3.new(0, 0, -playerConfigs.FrontDashDistance))
			print("Performing regular front dash.")
			InvincibilityEvent:FireServer(playerConfigs.DashDuration, "FrontDash")
		end

		stateMachine.AnimationHandler:Play("Dash_Front")
		stateMachine.SoundHandler:Play("Dash_Side")
		stateMachine.CameraHandler:ChangeFOV("Dash")
		playerConfigs.DashCharges -= 2
	end

	-- CURRENT_GHOST_TIME is specifically managed for BackDash, otherwise it defaults to 0.
	if not isBackDashing then
		CURRENT_GHOST_TIME = 0
	end

	return dashInitiated
end

function DashState:Enter(stateMachine)
	-- Attempt to initiate a dash. If no dash conditions are met, transition to Idle.
	local dashWasInitiated = self:HandleDashInput(stateMachine)
	if not dashWasInitiated then
		stateMachine:ChangeState(stateMachine.States.IdleState)
		return
	end
end

function DashState:Update(stateMachine, deltaTime)
	-- Continue current dash movement if duration is not over or if back-dashing is active
	if accumulatedTime <= stateMachine.Controller.PlayerConfigs.DashDuration or isBackDashing then
		accumulatedTime += deltaTime

		-- Handle target locking for auto-lock dash
		if self.Target and self.Target.Parent then
			local currentDistance = (self.Target.Position - stateMachine.HumanoidRP.Position).Magnitude
			-- The condition to end the dash early when close to target should remain.
			-- This prevents "sticking" to the target if the dash overshoots slightly.
			if currentDistance <= 5 then
				-- If close to target, end dash early
				accumulatedTime = stateMachine.Controller.PlayerConfigs.DashDuration + 0.1
				self.Target = nil
				-- Reset spring to prevent residual force
				DashSpring.shove(DashSpring, Vector3.new(0, 0, 0))
				DashSpring.update(DashSpring, 0.01)
				DashSpring.shove(DashSpring, Vector3.new(0, 0, 0))
				return
			end

			-- Orient player towards target
			stateMachine.HumanoidRP.CFrame = CFrame.lookAt(stateMachine.HumanoidRP.Position, self.Target.Position)
		end

		-- Apply spring movement to HumanoidRootPart
		local UpdatedPosition = DashSpring.update(DashSpring, deltaTime)
		stateMachine.HumanoidRP.CFrame *= CFrame.new(UpdatedPosition.X, UpdatedPosition.Y, UpdatedPosition.Z)
	else
		-- No new dash input, transition to appropriate movement state
		if InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
			if InputHandler.AllPressed(Enum.KeyCode.Q) then
				stateMachine:ChangeState(stateMachine.States.DashState)
			elseif
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
end

return DashState
