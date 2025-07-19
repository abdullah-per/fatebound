local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

local ClimbMoveState = BaseState.new("ClimbMoveState")

local LEDGE_CLIMB_GRACE = 0.3 -- Duration to ignore ground checks after a ledge climb
local SIDE_RAYCAST_DIST = 1.0 -- How far to check for side walls
local CLIMB_LERP_ALPHA = 0.35 -- Smoothness for wall movement
local CLIMB_UP_DURATION = 0.2 -- How long the climb-up animation should take (adjust as needed)

function ClimbMoveState:Enter(stateMachine)
	local humanoid = stateMachine.Humanoid
	humanoid.AutoRotate = false
	-- Disable general state machine (e.g., standard character movement)
	if stateMachine.Controller and stateMachine.Controller.MovementMachine then
		stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.MovementMachine, false)
	end
	-- Camera: set climbing FOV if available
	if
		stateMachine.Controller
		and stateMachine.Controller.MovementMachine
		and stateMachine.Controller.MovementMachine.CameraHandler
	then
		stateMachine.Controller.MovementMachine.CameraHandler:ChangeFOV("Climb")
	end
	-- Reset ledge climb grace, ensuring it starts fresh on enter
	stateMachine.JustClimbedLedge = false
	stateMachine.LedgeClimbTimer = 0
	stateMachine.IsClimbingUpLedge = false -- New flag for climb-up animation
	stateMachine.ClimbUpAlpha = 0 -- For smooth animation
end

function ClimbMoveState:Exit(stateMachine)
	-- Defensive checks
	if not stateMachine or not stateMachine.Humanoid then
		return
	end

	local humanoid = stateMachine.Humanoid
	humanoid.AutoRotate = true -- Re-enable auto-rotation

	-- Re-enable general state machine
	if stateMachine.Controller and stateMachine.Controller.MovementMachine then
		stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.MovementMachine, true)
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

function ClimbMoveState:HandleInput(stateMachine, input, eventType)
	if eventType ~= "began" then
		return
	end
	if input.KeyCode == Enum.KeyCode.X then
		stateMachine:ChangeState(stateMachine.States.DropState)
	end
end

function ClimbMoveState:Update(stateMachine, deltaTime)
	if stateMachine.IsDashing or stateMachine.IsClimbingUpLedge then -- Prevent movement during dash or climb-up animation
		if stateMachine.IsClimbingUpLedge then
			-- Handle the climb-up animation
			stateMachine.ClimbUpAlpha = math.min(1, stateMachine.ClimbUpAlpha + deltaTime / 0.5) -- Increased duration to 0.5s
			local currentPos = stateMachine.ClimbUpStartCFrame.Position
			local targetPos = stateMachine.ClimbUpEndCFrame.Position

			-- Smooth interpolation (ease in/out)
			local alpha = stateMachine.ClimbUpAlpha
			alpha = alpha * alpha * (3 - 2 * alpha) -- Smoothstep
			local newPos = currentPos:Lerp(targetPos, alpha)
			local newCFrame = CFrame.new(newPos, newPos + stateMachine.ClimbUpStartCFrame.LookVector)

			stateMachine.HumanoidRP.CFrame = newCFrame

			if stateMachine.ClimbUpAlpha >= 1 then
				stateMachine.IsClimbingUpLedge = false
				stateMachine:ChangeState(stateMachine.States.DropState)
			end
			return
		end
		return
	end

	local humanoidRoot = stateMachine.HumanoidRP
	local wallInfo = stateMachine.ClimbWallInfo
	local configs = stateMachine.Controller.PlayerConfigs

	-- Essential checks for state validity
	if not humanoidRoot or not wallInfo or not configs then
		stateMachine:ChangeState(stateMachine.States.DropState) -- Fall back to DropState if critical info is missing
		return
	end

	local wallNormal = wallInfo.WallNormal
	local wallPoint = wallInfo.WallPosition
	local worldUp = Vector3.new(0, 1, 0)
	local wallUp = (worldUp - worldUp:Dot(wallNormal) * wallNormal).Unit
	local wallRight = wallNormal:Cross(wallUp).Unit
	local rootSize = humanoidRoot.Size or Vector3.new(2, 2, 1)

	-- Always face the wall (counteract shiftlock and maintain climb orientation)
	humanoidRoot.CFrame = CFrame.new(humanoidRoot.Position, humanoidRoot.Position - wallNormal)

	-- Ledge climb grace timer
	-- This timer prevents immediate dropping after successfully climbing a ledge
	if stateMachine.JustClimbedLedge then
		stateMachine.LedgeClimbTimer = (stateMachine.LedgeClimbTimer or 0) + deltaTime
		if stateMachine.LedgeClimbTimer >= LEDGE_CLIMB_GRACE then
			stateMachine.JustClimbedLedge = false
			stateMachine.LedgeClimbTimer = 0
		end
	end

	-- Wall raycast: Check if still attached to the climbable wall
	local wallRayOrigin = humanoidRoot.Position + humanoidRoot.CFrame.LookVector * 0.2
	local wallRayDir = humanoidRoot.CFrame.LookVector * 5
	local wallParams = RaycastParams.new()
	wallParams.FilterDescendantsInstances = { stateMachine.Character }
	wallParams.FilterType = Enum.RaycastFilterType.Exclude
	local wallResult = workspace:Raycast(wallRayOrigin, wallRayDir, wallParams)
	local wallInFront = (wallResult and wallResult.Instance == wallInfo.WallPart) -- Check if hit the *same* wall

	-- Robust ground raycast: from root, straight down, moderate length
	-- This checks if there's solid ground *below* the player that isn't the current climb wall
	local groundRayOrigin = humanoidRoot.Position
	local groundRayDir = Vector3.new(0, -1, 0) * (rootSize.Y + 2) -- Restore previous, less aggressive ray length
	local groundParams = RaycastParams.new()
	groundParams.FilterDescendantsInstances = { stateMachine.Character, wallInfo.WallPart }
	groundParams.FilterType = Enum.RaycastFilterType.Exclude
	local groundResult = workspace:Raycast(groundRayOrigin, groundRayDir, groundParams)

	local groundBelow = false
	local groundY = nil
	if groundResult and groundResult.Instance then
		local dist = humanoidRoot.Position.Y - groundResult.Position.Y
		if dist < (rootSize.Y / 2 + 0.1) then -- Restore previous, less aggressive threshold
			groundBelow = true
			groundY = groundResult.Position.Y
		end
	end

	-- If ground is detected directly below AND we haven't just climbed a ledge,
	-- transition to DropState (e.g., if you walk off the side of the climbable wall)
	if groundBelow and not stateMachine.JustClimbedLedge then
		-- Snap to ground to avoid floating if you're truly on stable ground
		local pos = humanoidRoot.Position
		humanoidRoot.CFrame = CFrame.new(Vector3.new(pos.X, groundY + (rootSize.Y / 2), pos.Z), pos - wallNormal)
		stateMachine:ChangeState(stateMachine.States.DropState)
		return
	end

	-- Ledge check: Only attempt to climb a ledge if no wall is detected directly in front
	if not wallInFront then
		-- Cast a ray from slightly above and in front, downwards to detect a ledge surface
		local ledgeOrigin = humanoidRoot.Position + wallNormal * -0.5 + Vector3.new(0, rootSize.Y / 2 + 0.5, 0)
		local ledgeDir = Vector3.new(0, -1, 0) * (rootSize.Y + 2)
		local ledgeParams = RaycastParams.new()
		ledgeParams.FilterDescendantsInstances = { stateMachine.Character }
		ledgeParams.FilterType = Enum.RaycastFilterType.Exclude
		local ledgeResult = workspace:Raycast(ledgeOrigin, ledgeDir, ledgeParams)

		if ledgeResult and ledgeResult.Instance and ledgeResult.Instance ~= wallInfo.WallPart then
			-- Ledge found! Prepare for smooth climb-up animation
			stateMachine.IsClimbingUpLedge = true
			stateMachine.ClimbUpAlpha = 0
			stateMachine.ClimbUpStartCFrame = humanoidRoot.CFrame -- Store current CFrame

			-- Calculate the target CFrame for the end of the climb animation
			local upOffset = Vector3.new(0, rootSize.Y / 2 + 0.1, 0)
			local forwardOffset = wallNormal * -1 * (rootSize.Z / 2 + 0.1)
			local targetNewPos = ledgeResult.Position + upOffset + forwardOffset
			stateMachine.ClimbUpEndCFrame = CFrame.new(targetNewPos, targetNewPos - wallNormal)

			-- Do NOT change state yet, let the animation finish first
			return -- Exit Update early to let climb-up animation handle CFrame
		else
			-- No wall in front and no ledge above/forward, so pop off the wall
			if wallNormal then
				local popPos = humanoidRoot.Position - wallNormal.Unit * 2 + Vector3.new(0, 3, 0)
				humanoidRoot.CFrame = CFrame.new(popPos, popPos - wallNormal)
			else
				local popPos = humanoidRoot.Position + Vector3.new(0, 3, 0)
				humanoidRoot.CFrame = CFrame.new(popPos)
			end
			stateMachine:ChangeState(stateMachine.States.DropState)
			return
		end
	end

	-- Calculate desired movement direction based on input
	local desiredMoveDir = Vector3.new(0, 0, 0)
	if InputHandler.AnyPressed(Enum.KeyCode.W) then
		desiredMoveDir = desiredMoveDir + wallUp
	end
	if InputHandler.AnyPressed(Enum.KeyCode.S) then
		desiredMoveDir = desiredMoveDir - wallUp
	end
	if InputHandler.AnyPressed(Enum.KeyCode.A) then
		desiredMoveDir = desiredMoveDir + wallRight
	end
	if InputHandler.AnyPressed(Enum.KeyCode.D) then
		desiredMoveDir = desiredMoveDir - wallRight
	end

	if desiredMoveDir.Magnitude > 0 then
		desiredMoveDir = desiredMoveDir.Unit
		local currentMoveSpeed = configs.ClimbMoveSpeed

		-- SIDE RAYCASTS TO PREVENT CLIPPING
		local horizontalMove = desiredMoveDir - desiredMoveDir:Dot(worldUp) * worldUp -- Get horizontal component of desired movement

		if horizontalMove.Magnitude > 0 then
			horizontalMove = horizontalMove.Unit
			local checkDir = horizontalMove -- Direction to check for adjacent walls

			-- Determine if trying to move right or left relative to the wall
			local isMovingRight = desiredMoveDir:Dot(wallRight) < 0 -- Moving in negative wallRight direction (player's right)
			local isMovingLeft = desiredMoveDir:Dot(wallRight) > 0 -- Moving in positive wallRight direction (player's left)

			local sideRayOrigin = humanoidRoot.Position
			local sideRayDir = checkDir * SIDE_RAYCAST_DIST

			if isMovingRight then
				-- Raycast from the right side of the character, in the direction of intended right movement
				sideRayOrigin = humanoidRoot.Position + humanoidRoot.CFrame.RightVector * (rootSize.X / 2 + 0.1)
				sideRayDir = -wallRight * SIDE_RAYCAST_DIST -- Ray goes towards player's right
			elseif isMovingLeft then
				-- Raycast from the left side of the character, in the direction of intended left movement
				sideRayOrigin = humanoidRoot.Position - humanoidRoot.CFrame.RightVector * (rootSize.X / 2 + 0.1)
				sideRayDir = wallRight * SIDE_RAYCAST_DIST -- Ray goes towards player's left
			end

			local sideParams = RaycastParams.new()
			sideParams.FilterDescendantsInstances = { stateMachine.Character, wallInfo.WallPart } -- Exclude self and the current wall
			sideParams.FilterType = Enum.RaycastFilterType.Exclude

			local sideResult = workspace:Raycast(sideRayOrigin, sideRayDir, sideParams)

			if sideResult and sideResult.Instance then
				-- If a side wall is detected and it's not the current climbing wall
				local hitDistance = (sideResult.Position - sideRayOrigin).Magnitude
				if hitDistance <= (rootSize.X / 2 + 0.1) + 0.15 then -- If very close to or hitting the wall (add a small buffer)
					-- Clamp horizontal movement: remove the component that goes into the wall
					local originalDesiredMoveDir = desiredMoveDir
					desiredMoveDir = desiredMoveDir - desiredMoveDir:Dot(sideResult.Normal) * sideResult.Normal
					if desiredMoveDir.Magnitude > 0 then
						desiredMoveDir = desiredMoveDir.Unit
					else
						-- Project original movement onto the plane perpendicular to the wall's normal (slide along wall)
						desiredMoveDir = originalDesiredMoveDir
							- sideResult.Normal * originalDesiredMoveDir:Dot(sideResult.Normal)
						if desiredMoveDir.Magnitude > 0 then
							desiredMoveDir = desiredMoveDir.Unit
						else
							desiredMoveDir = Vector3.new(0, 0, 0)
						end
					end
				end
			end

			-- --- BEGIN: Diagonal (corner) raycasts to prevent corner clipping ---
			local diagonalDirs = {
				(wallUp + wallRight).Unit,
				(wallUp - wallRight).Unit,
				(-wallUp + wallRight).Unit,
				(-wallUp - wallRight).Unit,
			}
			for _, diagDir in ipairs(diagonalDirs) do
				local diagRayOrigin = humanoidRoot.Position
				local diagRayDir = diagDir * SIDE_RAYCAST_DIST
				local diagParams = RaycastParams.new()
				diagParams.FilterDescendantsInstances = { stateMachine.Character, wallInfo.WallPart }
				diagParams.FilterType = Enum.RaycastFilterType.Exclude
				local diagResult = workspace:Raycast(diagRayOrigin, diagRayDir, diagParams)
				if diagResult and diagResult.Instance then
					local hitDistance = (diagResult.Position - diagRayOrigin).Magnitude
					if hitDistance <= (rootSize.X / 2 + 0.1) + 0.15 then
						-- Clamp diagonal movement: remove the component that goes into the wall
						desiredMoveDir = desiredMoveDir - desiredMoveDir:Dot(diagResult.Normal) * diagResult.Normal
						if desiredMoveDir.Magnitude > 0 then
							desiredMoveDir = desiredMoveDir.Unit
						else
							desiredMoveDir = Vector3.new(0, 0, 0)
						end
					end
				end
			end
			-- --- END: Diagonal (corner) raycasts ---
		end

		if desiredMoveDir.Magnitude > 0 then -- Check again after potential clamping
			-- Calculate target position by moving along the wall plane
			-- CHANGED: Multiplied configs.ClimbMoveSpeed by 3 for increased speed
			local targetPos = humanoidRoot.Position + desiredMoveDir * (currentMoveSpeed * 3) * deltaTime

			-- Project the target position back onto the wall plane
			local toWall = targetPos - wallPoint
			local projected = targetPos - wallNormal * toWall:Dot(wallNormal)

			-- Apply an offset to keep the character a consistent distance from the wall
			local offsetDist = (rootSize.Z / 2) + 0.15
			local offset = wallNormal * offsetDist
			local finalPos = projected + offset

			-- Smoothly interpolate to the new position
			local newPos = humanoidRoot.Position:Lerp(finalPos, CLIMB_LERP_ALPHA)
			humanoidRoot.CFrame = CFrame.new(newPos, newPos - wallNormal)
		end
	end
end

return ClimbMoveState
