--// HealthBarHandler
-- Handles the health bar UI logic

local HealthBarHandler = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

function HealthBarHandler.Init(humanoid)
	local function getHealthBars()
		local gui = player:FindFirstChild("PlayerGui")
		if not gui then
			return nil, nil
		end
		local hud = gui:FindFirstChild("HUD")
		if not hud then
			return nil, nil
		end
		local constant = hud:FindFirstChild("Constant")
		if not constant then
			return nil, nil
		end
		local health = constant:FindFirstChild("Health")
		if not health then
			return nil, nil
		end
		local background = health:FindFirstChild("Background")
		if not background then
			return nil, nil
		end
		local bar = background:FindFirstChild("Bar")
		if not bar then
			return nil, nil
		end
		-- Corrected: SecondaryBar is a child of Background, not Bar
		local secondaryBar = background:FindFirstChild("SecondaryBar")
		return bar, secondaryBar -- Return both bars
	end

	local mainBarFill, secondaryBarFill = getHealthBars()
	if not mainBarFill then
		warn("Main health bar UI not found at PlayerGui.HUD.Constant.Health.Background.Bar")
		return
	end
	if not secondaryBarFill then
		warn("Secondary health bar UI not found at PlayerGui.HUD.Constant.Health.Background.SecondaryBar")
		-- Continue without secondary bar if not found, or exit if it's critical
		-- For now, we'll just warn and proceed with only the main bar.
	end

	-- Removed: Set initial color for the secondary bar if it exists (example color)
	-- if secondaryBarFill then
	--     secondaryBarFill.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- A distinct red/pink color
	-- end

	local function updateBar()
		local maxHealth = humanoid.MaxHealth
		local health = humanoid.Health
		local percent = math.clamp(health / maxHealth, 0, 1)

		-- Tween for the main bar (fast movement)
		TweenService:Create(mainBarFill, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(percent, 0, 1, 0),
		}):Play()

		-- Tween for the secondary bar (slower movement)
		TweenService:Create(secondaryBarFill, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(percent, 0, 1, 0),
		}):Play()
	end

	-- Initial update
	updateBar()

	humanoid.HealthChanged:Connect(updateBar)
	-- Also update if MaxHealth changes
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateBar)
end

return HealthBarHandler
