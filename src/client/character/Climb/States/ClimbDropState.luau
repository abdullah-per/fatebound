local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)

local ClimbDropState = BaseState.new("ClimbDropState")

function ClimbDropState:Enter(stateMachine)
	local humanoidRoot = stateMachine.HumanoidRP
	if humanoidRoot then
		humanoidRoot.Anchored = false
	end
	-- After a short delay, transition back to waiting state
	task.delay(0.2, function()
		stateMachine:ChangeState(stateMachine.States.WaitingState)
	end)
end

function ClimbDropState:HandleInput(stateMachine, input, eventType)
	-- No input handled during drop
end

function ClimbDropState:Update(stateMachine, deltaTime)
	-- No-op, transition handled by delay
end

return ClimbDropState
