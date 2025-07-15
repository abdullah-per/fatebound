local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerConfig = require(ReplicatedStorage.Shared.PlayerConfig)
local PlayerConfigEvent = require(ReplicatedStorage.Shared.Remotes.PlayerConfigEvent)

local PlayerConfigHandler = {}

-- Sends config to a player
function PlayerConfigHandler:SendConfig(player)
	local config = PlayerConfig:GetForPlayer(player)
	PlayerConfigEvent:FireClient(player, config)
end

-- Periodically resend configs for exploit protection
function PlayerConfigHandler:StartPeriodicResend()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			self:SendConfig(player)
		end
		wait(30) -- Resend every 30 seconds (adjust as needed)
	end
end

-- On player join, send config
Players.PlayerAdded:Connect(function(player)
	PlayerConfigHandler:SendConfig(player)
end)

-- On player request (optional, for manual resync)
PlayerConfigEvent.OnServerEvent:Connect(function(player)
	PlayerConfigHandler:SendConfig(player)
end)

return PlayerConfigHandler
