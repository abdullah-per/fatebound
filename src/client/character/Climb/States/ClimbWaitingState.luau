local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)

local ClimbWaitingState = BaseState.new("ClimbWaitingState")

local RAYCAST_INTERVAL = 0.1
local lastRaycast = 0

function ClimbWaitingState:Enter(stateMachine)
	lastRaycast = 0
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
	if result and result.Instance then
		local normal = result.Normal
		local up = Vector3.new(0, 1, 0)
		local angle = math.deg(math.acos(normal:Dot(up)))
		if angle >= configs.ClimbAttachAngleMin and angle <= configs.ClimbAttachAngleMax then
			-- Wall is climbable, store hit info and transition
			stateMachine.ClimbWallInfo = {
				WallPart = result.Instance,
				WallPosition = result.Position,
				WallNormal = result.Normal,
			}
			stateMachine:ChangeState(stateMachine.States.IdleState)
		end
	end
end

return ClimbWaitingState
