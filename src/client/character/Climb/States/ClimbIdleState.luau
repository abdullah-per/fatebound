local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

local ClimbIdleState = BaseState.new("ClimbIdleState")

-- Define constants for side collision detection
local SIDE_COLLISION_OFFSET = 0.2 -- How much to push away from a detected side wall
local SIDE_RAYCAST_LENGTH = 0.75 -- How far to cast rays to detect walls slightly further out

function ClimbIdleState:Enter(stateMachine)
	local character = stateMachine.Character
	local humanoid = stateMachine.Humanoid
	local humanoidRoot = stateMachine.HumanoidRP

	humanoidRoot.Anchored = true
	humanoid.AutoRotate = false
	local wallInfo = stateMachine.ClimbWallInfo

	if not wallInfo then
		stateMachine:ChangeState(stateMachine.States.DropState)
		return
	end

	local rootSize = humanoidRoot.Size or Vector3.new(2, 2, 1)
	local offsetDist = (rootSize.Z / 2) + 0.2
	local offset = wallInfo.WallNormal * offsetDist

	local targetPos = wallInfo.WallPosition + offset
	local targetCFrame = CFrame.new(targetPos, targetPos - wallInfo.WallNormal)

	local positionAdjustment = Vector3.new(0, 0, 0)
	local filterList = { character, wallInfo.WallPart }

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = filterList

	-- *** Enhanced Side/Corner Collision Detection with Multiple Rays ***
	local rayHeights = { -rootSize.Y / 2 + 0.1, 0, rootSize.Y / 2 - 0.1 } -- Bottom, Middle, Top of HumanoidRootPart
	local hitDetected = false

	-- Check Right Side with Multiple Rays
	for _, heightOffset in ipairs(rayHeights) do
		local rayOrigin = targetCFrame.Position
			+ targetCFrame.RightVector * (rootSize.X / 2)
			+ targetCFrame.UpVector * heightOffset
		local rayDirection = targetCFrame.RightVector * SIDE_RAYCAST_LENGTH
		local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)

		if result and result.Instance then
			local pushNormal = result.Normal
			-- Only apply adjustment once if multiple rays hit, to avoid over-adjusting
			if wallInfo.WallNormal:Dot(pushNormal) < 0.8 then -- Check if normals are somewhat aligned (not parallel to main wall)
				positionAdjustment = positionAdjustment - pushNormal * SIDE_COLLISION_OFFSET
				hitDetected = true
				break -- Exit loop if a hit is detected on this side
			else
				-- Fallback to direct push if normal check fails but still a hit
				positionAdjustment = positionAdjustment - targetCFrame.RightVector * SIDE_COLLISION_OFFSET
				hitDetected = true
				break
			end
		end
	end

	-- Reset hitDetected for the other side
	hitDetected = false

	-- Check Left Side with Multiple Rays
	for _, heightOffset in ipairs(rayHeights) do
		local rayOrigin = targetCFrame.Position
			- targetCFrame.RightVector * (rootSize.X / 2)
			+ targetCFrame.UpVector * heightOffset
		local rayDirection = -targetCFrame.RightVector * SIDE_RAYCAST_LENGTH
		local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)

		if result and result.Instance then
			local pushNormal = result.Normal
			if wallInfo.WallNormal:Dot(pushNormal) < 0.8 then
				positionAdjustment = positionAdjustment - pushNormal * SIDE_COLLISION_OFFSET
				hitDetected = true
				break
			else
				positionAdjustment = positionAdjustment + targetCFrame.RightVector * SIDE_COLLISION_OFFSET
				hitDetected = true
				break
			end
		end
	end

	humanoidRoot.CFrame = targetCFrame + positionAdjustment

	-- Disable movement and combat state machines
	if stateMachine.Controller and stateMachine.Controller.SetStateMachineEnabled then
		if stateMachine.Controller.MovementMachine then
			stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.MovementMachine, false)
		end
		if stateMachine.Controller.CombatMachine then
			stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.CombatMachine, false)
		end
	end

	-- Camera: set climbing FOV if available
	if
		stateMachine.Controller
		and stateMachine.Controller.MovementMachine
		and stateMachine.Controller.MovementMachine.CameraHandler
	then
		stateMachine.Controller.MovementMachine.CameraHandler:ChangeFOV("Climb")
	end

	-- Reset climbing stamina if needed
	stateMachine.ClimbStamina = stateMachine.Controller.PlayerConfigs.ClimbMaxStamina

	if
		InputHandler.AnyPressed(Enum.KeyCode.W)
		or InputHandler.AnyPressed(Enum.KeyCode.A)
		or InputHandler.AnyPressed(Enum.KeyCode.S)
		or InputHandler.AnyPressed(Enum.KeyCode.D)
	then
		stateMachine:ChangeState(stateMachine.States.MoveState)
		return
	end
end

function ClimbIdleState:Exit(stateMachine)
	if not stateMachine or not stateMachine.HumanoidRP then
		return
	end
	-- Unanchor on exit
	local humanoidRoot = stateMachine.HumanoidRP
	if humanoidRoot then
		humanoidRoot.Anchored = false
	end
	local humanoid = stateMachine.Humanoid
	if humanoid then
		humanoid.AutoRotate = true
	end
	-- Re-enable movement and combat state machines
	if stateMachine.Controller and stateMachine.Controller.SetStateMachineEnabled then
		if stateMachine.Controller.MovementMachine then
			stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.MovementMachine, true)
		end
		if stateMachine.Controller.CombatMachine then
			stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.CombatMachine, true)
		end
	end
	-- Camera: restore FOV
	if
		stateMachine.Controller
		and stateMachine.Controller.MovementMachine
		and stateMachine.Controller.MovementMachine.CameraHandler
	then
		stateMachine.Controller.MovementMachine.CameraHandler:ChangeFOV("Idle")
	end
end

function ClimbIdleState:HandleInput(stateMachine, input, eventType)
	if eventType ~= "began" then
		return
	end
	if input.KeyCode == Enum.KeyCode.Space then
		stateMachine:ChangeState(stateMachine.States.JumpState)
	elseif input.KeyCode == Enum.KeyCode.X then
		stateMachine:ChangeState(stateMachine.States.DropState)
	elseif InputHandler.AnyPressed(Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D) then
		stateMachine:ChangeState(stateMachine.States.MoveState)
	end
end

function ClimbIdleState:Update(stateMachine, deltaTime)
	-- Optionally, drain stamina slowly while latched
	if stateMachine.ClimbStamina then
		if stateMachine.ClimbStamina <= 0 then
			stateMachine:ChangeState(stateMachine.States.DropState)
		end
	end
	-- Ensure character always faces the wall (counteract shiftlock)
	local humanoidRoot = stateMachine.HumanoidRP
	local wallInfo = stateMachine.ClimbWallInfo
	if humanoidRoot and wallInfo then
		local rootSize = humanoidRoot.Size or Vector3.new(2, 2, 1)
		local offsetDist = (rootSize.Z / 2) + 0.2
		local offset = wallInfo.WallNormal * offsetDist
		humanoidRoot.CFrame = CFrame.new(humanoidRoot.Position, humanoidRoot.Position - wallInfo.WallNormal)
	end
end

return ClimbIdleState
