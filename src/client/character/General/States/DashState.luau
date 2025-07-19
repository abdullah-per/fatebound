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
	-- Keep original globals for compatibility, but manage self.Target
	self.Target = nil
	return self
end

local waitForGhost = false
local accumulatedTime = 0
local isBackDashing = false

function DashState:Enter(stateMachine)
	local playerConfigs = stateMachine.Controller.PlayerConfigs

	-- Reset accumulated time on entering state
	accumulatedTime = 0
	-- Reset target reference
	self.Target = nil

	-- Spring needs to be reset for each dash.
	-- Since Spring.reset() isn't available, we'll "zero out" the spring's internal velocity/position
	-- by shoving it with a zero vector before the actual shove. This is a common workaround.
	DashSpring.shove(DashSpring, Vector3.new(0, 0, 0))
	DashSpring.update(DashSpring, 0.01) -- Advance it slightly to clear any residual force
	DashSpring.shove(DashSpring, Vector3.new(0, 0, 0)) -- Shove with zero again

	if InputHandler.AllPressed(Enum.KeyCode.S) and playerConfigs.DashCharges >= 3 then -- back
		-- Disable combat state machine on backdash
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

		task.spawn(function()
			task.wait(stateMachine.AnimationHandler.Tracks.Dash_Back.Length + 0.1)
			stateMachine.AnimationHandler:Play("Ghost_Idle")
		end)

		stateMachine.SoundHandler:Play("Dash_Back")
		-- BackDashDistance should be negative for backward movement, if positive Z is forward.
		-- Assuming BackDashDistance is a positive magnitude, we apply it negatively.
		DashSpring.shove(DashSpring, Vector3.new(0, 0, playerConfigs.BackDashDistance))

		-- ghost dash logic
		CURRENT_GHOST_TIME = stateMachine.SoundHandler.Tracks.Dash_Back.TimeLength -- Use this for ghost duration
		stateMachine.Humanoid.WalkSpeed = 30

		waitForGhost = true
		isBackDashing = true
		local ragdoll = BackDash.Enable(stateMachine.Character)
		task.wait(CURRENT_GHOST_TIME)
		BackDash.Disable(stateMachine.Character, ragdoll)
		waitForGhost = false
		isBackDashing = false
		stateMachine.Humanoid.WalkSpeed = playerConfigs.WalkSpeed -- Restore speed after backdash

		-- Fire server event to replicate visual effects to other players
		BackDashEvent:FireServer()

		-- At the end of backdash, re-enable combat state machine
		task.spawn(function()
			task.wait(stateMachine.AnimationHandler.Tracks.Dash_Back.Length + 0.1)
			if stateMachine.Controller and stateMachine.Controller.SetStateMachineEnabled and combatMachine then
				stateMachine.Controller:SetStateMachineEnabled(combatMachine, true)
			end
		end)
	elseif InputHandler.AllPressed(Enum.KeyCode.A) and playerConfigs.DashCharges >= 1 then -- left
		stateMachine.AnimationHandler:Play("Dash_Left")
		stateMachine.SoundHandler:Play("Dash_Side")
		stateMachine.CameraHandler:ChangeFOV("Dash")

		playerConfigs.DashCharges -= 1
		DashSpring.shove(DashSpring, Vector3.new(-playerConfigs.SideDashDistance, 0, 0))
	elseif InputHandler.AllPressed(Enum.KeyCode.D) and playerConfigs.DashCharges >= 1 then -- right
		stateMachine.AnimationHandler:Play("Dash_Right")
		stateMachine.SoundHandler:Play("Dash_Side")
		stateMachine.CameraHandler:ChangeFOV("Dash")

		playerConfigs.DashCharges -= 1
		DashSpring.shove(DashSpring, Vector3.new(playerConfigs.SideDashDistance, 0, 0))
	elseif
		not InputHandler.AnyPressed(Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D)
		and playerConfigs.DashCharges >= 2
	then
		-- auto lock logic
		local nearestTarget = FindNearestTarget(stateMachine, playerConfigs.FrontDashMaxDistance, 90)

		if nearestTarget then
			self.Target = nearestTarget
			-- Calculate direction to target in world space
			local directionToTarget = (self.Target.Position - stateMachine.HumanoidRP.Position)
			-- Get the distance, subtracting a small buffer (e.g., 5 studs) to prevent overshooting/clipping
			-- Use playerConfigs.FrontDashDistance as a cap, or just the calculated distance minus buffer.
			local dashMagnitude = math.min(playerConfigs.FrontDashDistance, directionToTarget.Magnitude - 5) -- Fixed: subtract 5 studs from target distance
			dashMagnitude = math.max(0, dashMagnitude) -- Ensure it's not negative

			-- Convert the world-space direction vector to the player's local space
			-- This is crucial for DashSpring.shove which likely applies force in local space.
			local localDirectionToTarget = stateMachine.HumanoidRP.CFrame:VectorToObjectSpace(directionToTarget.Unit)

			-- Shove the spring with the calculated local direction and magnitude
			DashSpring.shove(DashSpring, localDirectionToTarget * dashMagnitude)

			print("Auto-locking onto: ", self.Target.Parent.Name, " - Dash magnitude:", dashMagnitude)
		else
			self.Target = nil
			-- Regular front dash if no target, shove in local backward direction for front dash (negative Z)
			DashSpring.shove(DashSpring, Vector3.new(0, 0, -playerConfigs.FrontDashDistance))
			print("Performing regular front dash.")
		end

		-- front dash animations/sounds
		stateMachine.AnimationHandler:Play("Dash_Front")
		stateMachine.SoundHandler:Play("Dash_Side")
		stateMachine.CameraHandler:ChangeFOV("Dash")
		playerConfigs.DashCharges -= 2
	else
		-- If no valid dash input, immediately exit the state.
		stateMachine:ChangeState(stateMachine.States.IdleState)
		return
	end

	CURRENT_GHOST_TIME = 0 -- Resetting ghost time after potential use in backdash
end

function DashState:Update(stateMachine, deltaTime)
	-- Apply Spring movement for all dash types
	-- Check if dash duration is still active OR if it's an active backdash (which has extended duration)
	if accumulatedTime <= stateMachine.Controller.PlayerConfigs.DashDuration or isBackDashing then
		accumulatedTime += deltaTime

		-- facing the target (only if a target is active)
		if self.Target and self.Target.Parent then -- Check if target still exists
			local currentDistance = (self.Target.Position - stateMachine.HumanoidRP.Position).Magnitude
			-- If we are close enough to the target, force the dash to end
			-- Using a fixed threshold (e.g., 5 studs) since we can't introduce a new config
			if currentDistance <= 5 then -- Fixed: Use a constant 5 studs as stop distance
				accumulatedTime = stateMachine.Controller.PlayerConfigs.DashDuration + 0.1 -- Force exit
				self.Target = nil -- Clear target
				-- Manually try to "reset" the spring motion by zeroing it out if no reset method
				DashSpring.shove(DashSpring, Vector3.new(0, 0, 0))
				DashSpring.update(DashSpring, 0.01)
				DashSpring.shove(DashSpring, Vector3.new(0, 0, 0))
				return
			end

			stateMachine.HumanoidRP.CFrame = CFrame.lookAt(stateMachine.HumanoidRP.Position, self.Target.Position)
		end

		-- updating spring position and humanoidRP
		local UpdatedPosition = DashSpring.update(DashSpring, deltaTime)
		stateMachine.HumanoidRP.CFrame *= CFrame.new(UpdatedPosition.X, UpdatedPosition.Y, UpdatedPosition.Z)
	else
		-- Dash duration finished, transition to appropriate state
		accumulatedTime = 0 -- reset for next dash

		-- Determine next state based on current input
		if InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
			-- If any movement key is held, go to Run/Walk state
			if
				stateMachine.PreviousState == stateMachine.States.RunState
				or stateMachine.BeforePreviousState == stateMachine.States.RunState
			then
				stateMachine:ChangeState(stateMachine.States.RunState)
			else
				stateMachine:ChangeState(stateMachine.States.WalkState)
			end
		else
			-- If no movement keys, go to Idle state
			stateMachine:ChangeState(stateMachine.States.IdleState)
		end
		self.Target = nil -- Clear target on exit
	end
end

return DashState
