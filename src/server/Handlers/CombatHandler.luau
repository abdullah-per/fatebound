--[[
	Combat Handler
	==============
	
	Server-side combat system that handles all combat-related events and actions.
	Provides anti-exploit protection, damage calculation, and combat effects
	like stun and movement modifications.
	
	Features:
	- Server-side combat validation
	- Anti-exploit protection (cooldowns, range limits, damage caps)
	- Configurable damage values and stun effects
	- Player attack tracking and rate limiting
	- Comprehensive error handling and logging
	
	Security Features:
	- Attack cooldown enforcement
	- Maximum attack range validation
	- Target count limits
	- Damage per second limits
	- Player data cleanup on disconnect
	
	Usage:
		-- Handle hit events from clients
		CombatHandler.HandleHitEvent(player, "LightAttack", {targetCharacter})
		
		-- Initialize the combat system
		CombatHandler.Init()
	
	@author Fatebound Team
	@version 1.0.0
--]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

--// Configuration
local DAMAGE_VALUES = {
	LightAttack = 10,
	HeavyAttack = 25,
}

local STUN_DURATION = 0.5 -- seconds

--// Security Configuration
local MAX_ATTACK_RANGE = 8 -- studs (maximum allowed attack range)
local MAX_TARGETS_PER_ATTACK = 5 -- maximum targets per attack
local MIN_ATTACK_COOLDOWN = 0.1 -- seconds between attacks
local MAX_DAMAGE_PER_SECOND = 100 -- maximum damage per second per player

--// Combat Handler
local CombatHandler = {}

--// Player attack tracking for anti-exploit
local playerAttackCooldowns = {}
local playerDamagePerSecond = {}

--// Check if attack is valid
function CombatHandler.IsValidAttack(player, attackType, targetCharacters)
	if not player or not player.Character then
		return false, "Invalid player"
	end

	local hitterCharacter = player.Character
	local hitterRootPart = hitterCharacter:FindFirstChild("HumanoidRootPart")

	if not hitterRootPart then
		return false, "No root part"
	end

	-- Check attack cooldown
	local currentTime = os.clock()
	local lastAttackTime = playerAttackCooldowns[player.UserId] or 0

	if currentTime - lastAttackTime < MIN_ATTACK_COOLDOWN then
		return false, "Attack too fast"
	end

	-- Check target count
	if #targetCharacters > MAX_TARGETS_PER_ATTACK then
		return false, "Too many targets"
	end

	-- Check attack range for each target
	for _, targetCharacter in ipairs(targetCharacters) do
		if targetCharacter and targetCharacter ~= hitterCharacter then
			local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
			if targetRootPart then
				local distance = (targetRootPart.Position - hitterRootPart.Position).Magnitude
				if distance > MAX_ATTACK_RANGE then
					return false, "Target too far"
				end
			end
		end
	end

	-- Check damage per second limit
	local damage = DAMAGE_VALUES[attackType] or 10
	local totalDamage = damage * #targetCharacters

	if not playerDamagePerSecond[player.UserId] then
		playerDamagePerSecond[player.UserId] = { damage = 0, lastReset = currentTime }
	end

	local dpsData = playerDamagePerSecond[player.UserId]

	-- Reset damage counter if a second has passed
	if currentTime - dpsData.lastReset >= 1 then
		dpsData.damage = 0
		dpsData.lastReset = currentTime
	end

	dpsData.damage += totalDamage

	if dpsData.damage > MAX_DAMAGE_PER_SECOND then
		return false, "Damage per second limit exceeded"
	end

	return true, "Valid attack"
end

--// Handle hit events from clients
function CombatHandler.HandleHitEvent(player, attackType, targetCharacters)
	-- Validate the attack
	local isValid, reason = CombatHandler.IsValidAttack(player, attackType, targetCharacters)
	if not isValid then
		-- Log potential exploit attempt
		print(string.format("Combat exploit attempt by %s: %s", player.Name, reason))
		return
	end

	local hitterCharacter = player.Character
	local hitterRootPart = hitterCharacter:FindFirstChild("HumanoidRootPart")
	local hitterHumanoid = hitterCharacter:FindFirstChild("Humanoid")

	if not hitterRootPart or not hitterHumanoid then
		return
	end

	local damage = DAMAGE_VALUES[attackType] or 10

	-- Update attack cooldown
	playerAttackCooldowns[player.UserId] = os.clock()

	-- Process each target
	for _, targetCharacter in ipairs(targetCharacters) do
		if targetCharacter and targetCharacter ~= hitterCharacter then
			CombatHandler.ProcessHit(hitterCharacter, targetCharacter, damage, attackType)
		end
	end
end

--// Process a single hit
function CombatHandler.ProcessHit(hitterCharacter, targetCharacter, damage, attackType)
	local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
	local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
	local hitterRootPart = hitterCharacter:FindFirstChild("HumanoidRootPart")

	if not targetHumanoid or not targetRootPart or not hitterRootPart then
		return
	end

	-- Calculate direction from hitter to target
	local direction = (targetRootPart.Position - hitterRootPart.Position).Unit

	-- Apply damage
	targetHumanoid.Health = math.max(0, targetHumanoid.Health - damage)

	-- Apply stun (disable movement temporarily)
	CombatHandler.ApplyStun(targetCharacter, STUN_DURATION)
end

--// Apply stun to a character
function CombatHandler.ApplyStun(character, duration)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	-- Store original walk speed
	local originalWalkSpeed = humanoid.WalkSpeed

	-- Disable movement
	humanoid.WalkSpeed = 0

	-- Re-enable movement after stun duration
	task.spawn(function()
		task.wait(duration)
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = originalWalkSpeed
		end
	end)
end

--// Clean up player data when they leave
function CombatHandler.CleanupPlayerData(player)
	if player then
		playerAttackCooldowns[player.UserId] = nil
		playerDamagePerSecond[player.UserId] = nil
	end
end

--// Initialize the combat handler
function CombatHandler.Init()
	local HitEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat"):WaitForChild("HitEvent")

	-- Connect to hit events from clients
	HitEvent.OnServerEvent:Connect(function(player, attackType, targetCharacters)
		CombatHandler.HandleHitEvent(player, attackType, targetCharacters)
	end)

	-- Clean up player data when they leave
	Players.PlayerRemoving:Connect(function(player)
		CombatHandler.CleanupPlayerData(player)
	end)
end

return CombatHandler
