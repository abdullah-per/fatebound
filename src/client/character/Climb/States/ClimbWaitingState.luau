local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local UserInputService = game:GetService("UserInputService")

local ClimbWaitingState = BaseState.new("ClimbWaitingState")

local RAYCAST_INTERVAL = 0.03
local lastRaycast = 0
local wallDetectTimer = 0
local wallDetectedLastFrame = false

function ClimbWaitingState:Enter(stateMachine)
	lastRaycast = 0
	wallDetectTimer = 0
	wallDetectedLastFrame = false
end

function ClimbWaitingState:HandleInput(stateMachine, input, eventType)
	-- No input handled in waiting state
end

function ClimbWaitingState:Update(stateMachine, deltaTime)
	lastRaycast = lastRaycast + deltaTime
	if lastRaycast < RAYCAST_INTERVAL then
		return
	end
	lastRaycast = 0

	local character = stateMachine.Character
	local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRoot then
		return
	end

	local configs = stateMachine.Controller.PlayerConfigs
	local rayOrigin = humanoidRoot.Position
	local rayDirection = humanoidRoot.CFrame.LookVector * configs.ClimbAttachDistance

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	local holdingW = UserInputService:IsKeyDown(Enum.KeyCode.W)

	if result and result.Instance then
		local normal = result.Normal
		local up = Vector3.new(0, 1, 0)
		local angle = math.deg(math.acos(normal:Dot(up)))
		if angle >= configs.ClimbAttachAngleMin and angle <= configs.ClimbAttachAngleMax and holdingW then
			if wallDetectedLastFrame then
				wallDetectTimer = wallDetectTimer + RAYCAST_INTERVAL
			else
				wallDetectTimer = RAYCAST_INTERVAL
			end
			wallDetectedLastFrame = true
			if wallDetectTimer >= 0.3 then
				-- Wall is climbable, store hit info and transition
				stateMachine.ClimbWallInfo = {
					WallPart = result.Instance,
					WallPosition = result.Position,
					WallNormal = result.Normal,
				}
				stateMachine:ChangeState(stateMachine.States.IdleState)
			end
		else
			wallDetectTimer = 0
			wallDetectedLastFrame = false
		end
	else
		wallDetectTimer = 0
		wallDetectedLastFrame = false
	end
end

return ClimbWaitingState
