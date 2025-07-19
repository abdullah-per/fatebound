--// BlockBarHandler
-- Handles the block overload UI bar logic

local BlockBarHandler = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local BlockOverloadVisualEvent =
	ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("BlockOverloadVisualEvent")

local GeneralStateMachine = require(script.Parent.Parent.General.GeneralMachine)

function BlockBarHandler.Init()
	local function getBlockBar()
		local gui = player:FindFirstChild("PlayerGui")
		if not gui then
			return nil
		end
		local hud = gui:FindFirstChild("HUD")
		if not hud then
			return nil
		end
		local variable = hud:FindFirstChild("Variable")
		if not variable then
			return nil
		end
		local blockbar = variable:FindFirstChild("Block")
		if not blockbar then
			return nil
		end
		local background = blockbar:FindFirstChild("Background")
		if not background then
			return nil
		end
		local bar = background:FindFirstChild("Bar")
		return bar
	end

	local barFill = getBlockBar()
	local blockBar = barFill.Parent
	if not blockBar then
		warn("Block bar UI not found at PlayerGui.HUD.Variable.Background.Bar")
		return
	end

	blockBar.Visible = false
	barFill.Size = UDim2.new(0, 0, 1, 0)
	blockBar.BackgroundTransparency = 1
	barFill.BackgroundTransparency = 1

	local function updateBlockBar(data)
		local overload = data.blockOverload or 0
		local limit = data.blockLimit or 1
		local isBlocking = data.isBlocking

		print(overload)

		local percent = math.clamp(overload / limit, 0, 1)

		TweenService:Create(barFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(percent, 0, 1, 0),
		}):Play()

		if overload > 0 then
			if not blockBar.Visible then
				blockBar.Visible = true
			end
			TweenService:Create(blockBar, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
			TweenService:Create(barFill, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
		else
			TweenService:Create(blockBar, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(barFill, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
			task.spawn(function()
				task.wait(0.2)
				blockBar.Visible = false
			end)
		end

		if overload >= limit then
			-- Switch to IdleState if block bar is full
			GeneralStateMachine:ChangeState(GeneralStateMachine.States.IdleState)
			GeneralStateMachine:Disable()
			task.wait(1.5)
			GeneralStateMachine:Enable(GeneralStateMachine.States.IdleState)
		end
	end

	BlockOverloadVisualEvent.OnClientEvent:Connect(updateBlockBar)
end

return BlockBarHandler
