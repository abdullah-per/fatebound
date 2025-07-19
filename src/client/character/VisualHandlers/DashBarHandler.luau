--// DashBarHandler
-- Handles the dash charges bar UI logic

local DashBarHandler = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

function DashBarHandler.Init(GeneralMachine)
	local function getDashBar()
		local gui = player:FindFirstChild("PlayerGui")
		if not gui then
			return nil
		end
		local hud = gui:FindFirstChild("HUD")
		if not hud then
			return nil
		end
		local constant = hud:FindFirstChild("Constant")
		if not constant then
			return nil
		end
		local dash = constant:FindFirstChild("Dash")
		if not dash then
			return nil
		end
		local background = dash:FindFirstChild("Background")
		if not background then
			return nil
		end
		local bar = background:FindFirstChild("Bar")
		return bar
	end

	local barFill = getDashBar()
	if not barFill then
		warn("Dash bar UI not found at PlayerGui.HUD.Constant.Dash.Background.Bar")
		return
	end

	local function updateBar()
		local configs = GeneralMachine.Controller.PlayerConfigs
		local charges = configs.DashCharges or 0
		local maxCharges = configs.MaxDashCharges or 1
		local percent = math.clamp(charges / maxCharges, 0, 1)
		TweenService:Create(barFill, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(percent, 0, 1, 0),
		}):Play()
	end

	-- Initial update
	updateBar()

	-- Hook into the update loop (DelegateUpdate is called every frame)
	local oldDelegateUpdate = GeneralMachine.DelegateUpdate
	function GeneralMachine:DelegateUpdate(deltaTime)
		oldDelegateUpdate(self, deltaTime)
		updateBar()
	end
end

return DashBarHandler
