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
local CURRENT_GHOST_TIME = 0

--// Instances
local DashSpring = Spring.create(Spring, 7)

--// Nearest Target
function FindNearestTarget(stateMachine, maxDistance, coneAngle)
	local playerCharacter = stateMachine.Character
	local playerHumanoidRP = stateMachine.HumanoidRP
	local playerLookVector = playerHumanoidRP.CFrame.lookVector

	local nearestTarget = nil
	local shortestDistance = math.huge

	-- Calculate the minimum dot product required for a target to be within the cone.
	-- Dot product of two unit vectors A and B is cos(theta), where theta is the angle between them.
	-- If the cone angle is 60 degrees, we want targets within +/- 30 degrees from the look vector.
	-- So, the angle is 30 degrees, and cos(30) is sqrt(3)/2 approx 0.866.
	local maxDotProduct = math.cos(math.rad(coneAngle / 2))

	-- Search for other players
	for _, player in ipairs(Players:GetPlayers()) do
		local targetCharacter = player.Character
		if targetCharacter and targetCharacter ~= playerCharacter then -- Ensure it's not the current player
			local targetHumanoidRP = targetCharacter:FindFirstChild("HumanoidRootPart")
			if targetHumanoidRP and targetCharacter:FindFirstChildOfClass("Humanoid") then
				local distance = (targetHumanoidRP.Position - playerHumanoidRP.Position).Magnitude
				if distance <= maxDistance then
					local directionToTarget = (targetHumanoidRP.Position - playerHumanoidRP.Position).Unit
					local dotProduct = playerLookVector:Dot(directionToTarget)

					if dotProduct >= maxDotProduct then -- Check if within the frontal cone
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

					if dotProduct >= maxDotProduct then -- Check if within the frontal cone
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
	return self
end

local waitForGhost = false
local accumulatedTime = 0
local isBackDashing = false

function DashState:Enter(stateMachine)
	local playerConfigs = stateMachine.Controller.PlayerConfigs

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
		DashSpring.shove(DashSpring, Vector3.new(0, 0, playerConfigs.BackDashDistance))

		-- ghost dash logic
		CURRENT_GHOST_TIME = stateMachine.SoundHandler.Tracks.Dash_Back.TimeLength
		stateMachine.Humanoid.WalkSpeed = 30

		waitForGhost = true
		isBackDashing = true
		local ragdoll = BackDash.Enable(stateMachine.Character)
		task.wait(CURRENT_GHOST_TIME)
		BackDash.Disable(stateMachine.Character, ragdoll)
		waitForGhost = false
		isBackDashing = false

		-- Fire server event to replicate visual effects to other players
		-- Only fire when backdash is actually successful
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
			DashSpring.shove(
				DashSpring,
				Vector3.new(0, 0, -(self.Target.Position - stateMachine.HumanoidRP.Position).Magnitude - 3)
			)

			print(self.Target.Parent)
		else
			self.Target = nil
			DashSpring.shove(DashSpring, Vector3.new(0, 0, -playerConfigs.FrontDashDistance))
		end

		-- front dash
		stateMachine.AnimationHandler:Play("Dash_Front")
		stateMachine.SoundHandler:Play("Dash_Side")
		stateMachine.CameraHandler:ChangeFOV("Dash")
		playerConfigs.DashCharges -= 2
	else
		accumulatedTime += 0.4
	end

	CURRENT_GHOST_TIME = 0 -- resetting ghost
end

function DashState:Update(stateMachine, deltaTime)
	-- Apply Spring movement for all dash types
	if accumulatedTime <= stateMachine.Controller.PlayerConfigs.DashDuration or isBackDashing then
		accumulatedTime += deltaTime

		-- facing the target
		if self.Target then
			print((self.Target.Position - stateMachine.HumanoidRP.Position).Magnitude)

			if (self.Target.Position - stateMachine.HumanoidRP.Position).Magnitude <= 3 then
				accumulatedTime += stateMachine.Controller.PlayerConfigs.DashDuration
				self.Target = nil
				return
			end

			stateMachine.HumanoidRP.CFrame = CFrame.lookAt(stateMachine.HumanoidRP.Position, self.Target.Position)
		end

		-- updating spring position and humanoidRP
		local UpdatedPosition = DashSpring.update(DashSpring, deltaTime)
		stateMachine.HumanoidRP.CFrame *= CFrame.new(UpdatedPosition.X, UpdatedPosition.Y, UpdatedPosition.Z)
	else
		if waitForGhost then
			return
		end

		accumulatedTime = 0 -- reset for next dash

		if InputHandler.AllPressed(Enum.KeyCode.Q) then
			DashState:Enter(stateMachine)
		elseif InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
			self.Target = nil

			-- Check if we should return to running state
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
end

return DashState
