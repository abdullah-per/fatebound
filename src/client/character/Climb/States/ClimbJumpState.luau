local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)

local ClimbJumpState = BaseState.new("ClimbJumpState")

function ClimbJumpState:Enter(stateMachine)
	local humanoidRoot = stateMachine.HumanoidRP
	local wallInfo = stateMachine.ClimbWallInfo
	local configs = stateMachine.Controller.PlayerConfigs
	if not humanoidRoot or not wallInfo then
		return
	end

	if stateMachine.ClimbStamina and stateMachine.ClimbStamina >= configs.ClimbStaminaJumpCost then
		stateMachine.ClimbStamina = stateMachine.ClimbStamina - configs.ClimbStaminaJumpCost
		-- Unanchor and apply jump velocity
		humanoidRoot.Anchored = false
		local jumpVec = wallInfo.WallNormal * 10 + Vector3.new(0, configs.ClimbJumpBoost, 0)
		humanoidRoot.Velocity = jumpVec
		-- After a short delay, transition to DropState
		task.delay(0.3, function()
			stateMachine:ChangeState(stateMachine.States.DropState)
		end)
	else
		-- Not enough stamina, just drop
		stateMachine:ChangeState(stateMachine.States.DropState)
	end
end

function ClimbJumpState:HandleInput(stateMachine, input, eventType)
	-- No input handled during jump
end

function ClimbJumpState:Update(stateMachine, deltaTime)
	-- No-op, transition handled by delay
end

return ClimbJumpState
