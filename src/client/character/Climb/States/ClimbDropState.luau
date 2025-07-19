local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)

local ClimbDropState = BaseState.new("ClimbDropState")

function ClimbDropState:Enter(stateMachine)
	local humanoidRoot = stateMachine.HumanoidRP
	local humanoid = stateMachine.Humanoid
	if humanoidRoot then
		humanoidRoot.Anchored = false
	end
	-- After a short delay, re-enable everything and transition back to waiting state
	task.delay(0.2, function()
		if humanoid then
			humanoid.AutoRotate = true
		end
		if stateMachine.Controller and stateMachine.Controller.MovementMachine then
			stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.MovementMachine, true)
		end
		if stateMachine.Controller and stateMachine.Controller.CombatMachine then
			stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.CombatMachine, true)
		end
		if
			stateMachine.Controller
			and stateMachine.Controller.MovementMachine
			and stateMachine.Controller.MovementMachine.CameraHandler
		then
			stateMachine.Controller.MovementMachine.CameraHandler:ChangeFOV("Idle")
		end
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
