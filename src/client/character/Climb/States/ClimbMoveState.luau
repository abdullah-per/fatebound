local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

local ClimbMoveState = BaseState.new("ClimbMoveState")

function ClimbMoveState:Enter(stateMachine)
	-- No-op for now
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
	local humanoidRoot = stateMachine.HumanoidRP
	local wallInfo = stateMachine.ClimbWallInfo
	local configs = stateMachine.Controller.PlayerConfigs
	if not humanoidRoot or not wallInfo then
		return
	end

	-- Calculate movement direction
	local moveDir = Vector3.new(0, 0, 0)
	if InputHandler.AnyPressed(Enum.KeyCode.W) then
		moveDir = moveDir + wallInfo.WallNormal:Cross(Vector3.new(1, 0, 0)).Unit -- up
	end
	if InputHandler.AnyPressed(Enum.KeyCode.S) then
		moveDir = moveDir - wallInfo.WallNormal:Cross(Vector3.new(1, 0, 0)).Unit -- down
	end
	if InputHandler.AnyPressed(Enum.KeyCode.A) then
		moveDir = moveDir - wallInfo.WallNormal:Cross(Vector3.new(0, 1, 0)).Unit -- left
	end
	if InputHandler.AnyPressed(Enum.KeyCode.D) then
		moveDir = moveDir + wallInfo.WallNormal:Cross(Vector3.new(0, 1, 0)).Unit -- right
	end

	if moveDir.Magnitude > 0 then
		moveDir = moveDir.Unit
		local targetPos = humanoidRoot.Position + moveDir * configs.ClimbMoveSpeed * deltaTime
		-- Project targetPos onto wall
		local wallPoint = wallInfo.WallPosition
		local wallNormal = wallInfo.WallNormal
		local toWall = targetPos - wallPoint
		local projected = targetPos - wallNormal * toWall:Dot(wallNormal)
		-- Lerp for smoothness
		humanoidRoot.Position = humanoidRoot.Position:Lerp(projected, 0.3)
		-- Drain stamina
		stateMachine.ClimbStamina = stateMachine.ClimbStamina - configs.ClimbStaminaDrainPerSecond * deltaTime
		if stateMachine.ClimbStamina <= 0 then
			stateMachine:ChangeState(stateMachine.States.DropState)
		end
	else
		stateMachine:ChangeState(stateMachine.States.IdleState)
	end
end

return ClimbMoveState
