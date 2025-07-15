local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseState = require(ReplicatedStorage.Shared.BaseClasses.BaseState)
local InputHandler = require(ReplicatedStorage.Shared.Utilities.InputHandler)

local ClimbIdleState = BaseState.new("ClimbIdleState")

function ClimbIdleState:Enter(stateMachine)
	local character = stateMachine.Character
	local humanoid = stateMachine.Humanoid
	local humanoidRoot = stateMachine.HumanoidRP

	-- Latch to wall: anchor and set CFrame flush to wall
	humanoidRoot.Anchored = true
	local wallInfo = stateMachine.ClimbWallInfo
	if wallInfo then
		local offset = wallInfo.WallNormal * 1 -- 1 stud away from wall
		humanoidRoot.CFrame =
			CFrame.new(wallInfo.WallPosition + offset, wallInfo.WallPosition + offset + wallInfo.WallNormal)
	end

	-- Disable movement and combat state machines
	if stateMachine.Controller and stateMachine.Controller.SetStateMachineEnabled then
		stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.MovementMachine, false)
		stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.CombatMachine, false)
	end

	-- Reset climbing stamina if needed
	stateMachine.ClimbStamina = stateMachine.Controller.PlayerConfigs.ClimbMaxStamina
end

function ClimbIdleState:Exit(stateMachine)
	-- Unanchor on exit
	local humanoidRoot = stateMachine.HumanoidRP
	if humanoidRoot then
		humanoidRoot.Anchored = false
	end
	-- Re-enable movement and combat state machines
	if stateMachine.Controller and stateMachine.Controller.SetStateMachineEnabled then
		stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.MovementMachine, true)
		stateMachine.Controller:SetStateMachineEnabled(stateMachine.Controller.CombatMachine, true)
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
end

return ClimbIdleState
