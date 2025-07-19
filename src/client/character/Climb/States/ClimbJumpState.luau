local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)

local ClimbJumpState = BaseState.new("ClimbJumpState")

function ClimbJumpState:Enter(stateMachine)
	local humanoidRoot = stateMachine.HumanoidRP
	local humanoid = stateMachine.Humanoid
	local wallInfo = stateMachine.ClimbWallInfo
	local configs = stateMachine.Controller.PlayerConfigs
	if not humanoidRoot or not wallInfo then
		return
	end

	humanoid.AutoRotate = false
	if stateMachine.Controller and stateMachine.Controller.MovementMachine then
		stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.MovementMachine, false)
	end
	if
		stateMachine.Controller
		and stateMachine.Controller.MovementMachine
		and stateMachine.Controller.MovementMachine.CameraHandler
	then
		stateMachine.Controller.MovementMachine.CameraHandler:ChangeFOV("Climb")
	end

	if stateMachine.ClimbStamina and stateMachine.ClimbStamina >= configs.ClimbStaminaJumpCost then
		stateMachine.ClimbStamina = stateMachine.ClimbStamina - configs.ClimbStaminaJumpCost
		-- Smooth wall dash: move up the wall over several frames
		local wallNormal = wallInfo.WallNormal
		local worldUp = Vector3.new(0, 1, 0)
		local wallUp = (worldUp - worldUp:Dot(wallNormal) * wallNormal).Unit
		local dashDistance = configs.ClimbJumpBoost or 5
		local startPos = humanoidRoot.Position
		local targetPos = startPos + wallUp * dashDistance
		local wallPoint = wallInfo.WallPosition
		local toWall = targetPos - wallPoint
		local projected = targetPos - wallNormal * toWall:Dot(wallNormal)
		stateMachine.IsDashing = true
		local duration = 0.18
		local elapsed = 0
		task.spawn(function()
			while elapsed < duration do
				local alpha = elapsed / duration
				local newPos = startPos:Lerp(projected, alpha)
				humanoidRoot.CFrame = CFrame.new(newPos, newPos - wallNormal)
				elapsed = elapsed + task.wait()
			end
			humanoidRoot.CFrame = CFrame.new(projected, projected - wallNormal)
			stateMachine.IsDashing = false
			stateMachine:ChangeState(stateMachine.States.IdleState)
		end)
	else
		-- Not enough stamina, just drop
		stateMachine:ChangeState(stateMachine.States.DropState)
	end
end

function ClimbJumpState:Exit(stateMachine)
	if not stateMachine or not stateMachine.Humanoid then
		return
	end
	local humanoid = stateMachine.Humanoid
	if humanoid then
		humanoid.AutoRotate = true
	end
	if stateMachine.Controller and stateMachine.Controller.MovementMachine then
		stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.MovementMachine, true)
	end
	if
		stateMachine.Controller
		and stateMachine.Controller.MovementMachine
		and stateMachine.Controller.MovementMachine.CameraHandler
	then
		stateMachine.Controller.MovementMachine.CameraHandler:ChangeFOV("Idle")
	end
end

function ClimbJumpState:HandleInput(stateMachine, input, eventType)
	-- No input handled during jump
end

function ClimbJumpState:Update(stateMachine, deltaTime)
	-- No-op, transition handled by delay
end

return ClimbJumpState
