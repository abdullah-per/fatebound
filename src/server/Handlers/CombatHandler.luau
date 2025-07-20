--
-- CombatHandler
--
-- Handles all server-side combat logic, including attack validation, damage application,
-- block overload, and anti-exploit protections. Provides a public API for combat events.
--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Configuration
-- DAMAGE_VALUES table has been removed. Damage is now specified by the caller.
local MAX_ATTACK_RANGE = 8
local MAX_TARGETS_PER_ATTACK = 5
local MIN_ATTACK_COOLDOWN = 0.1
local MAX_DAMAGE_PER_SECOND = 100
local BLOCK_OVERLOAD_FOR_ALL_DAMAGE = true -- Set to false to disable block overload for all damage
local BLOCK_OVERLOAD_REDUCTION_PER_SECOND = 5 -- New constant for how fast overload reduces
local BLOCK_OVERLOAD_REDUCTION_INTERVAL = 0.2 -- How often to reduce overload (e.g., 5 times per second)

-- Stun Type Definitions (as constants)
local STUN_TYPES = {
	-- Name = { WalkSpeedMultiplier, Duration }
	-- For simplicity, canAttack, canDash, canBlock are conceptual flags for client-side enforcement/UI.
	-- Server-side, 'isStunned' primarily controls actions.
	Soft = { WalkSpeedMultiplier = 0.5, Duration = 0.25 }, -- Example values
	Hard = { WalkSpeedMultiplier = 0.0, Duration = 0.5 }, -- Example values
	True = { WalkSpeedMultiplier = 0.0, Duration = 2.0 }, -- Example values (e.g., for block breaks)
}

-- State
-- playerStates[userId] will store all combat-related states for a player.
local playerStates = {} -- [userId] = { isBlocking = false, blockOverload = 0, isStunned = false, currentStunType = nil, stunEndTime = 0, isInvincible = false, originalWalkSpeed = 16 }
local playerAttackCooldowns = {}
local playerDamagePerSecond = {}
-- stunThreads will store active task.spawn threads for stuns, allowing cancellation
local stunThreads = {} -- [userId] = { [stunType] = threadObject, ... }

-- Remotes
local BlockEvent = require(ReplicatedStorage.Shared.Remotes.Combat.BlockEvent)
local BlockOverloadVisualEvent = require(ReplicatedStorage.Shared.Remotes.Combat.BlockOverloadVisualEvent)
-- New RemoteEvent for Invincibility
local InvincibilityEvent = require(ReplicatedStorage.Shared.Remotes.Combat.InvincibilityEvent)
-- New RemoteEvent for Stun Visuals
local StunEvent = require(ReplicatedStorage.Shared.Remotes.Combat.StunEvent)

local CombatHandler = {}

-- Utility: Retrieve player config safely
local function getPlayerConfig(player)
	local PlayerConfig = ReplicatedStorage.Shared:FindFirstChild("PlayerConfig")
	if PlayerConfig and PlayerConfig:IsA("ModuleScript") then
		local configModule = require(PlayerConfig)
		return configModule:GetForPlayer(player)
	end
	warn("PlayerConfig module not found or invalid.")
	return {}
end

-- Utility: Get or initialize player state safely
local function getPlayerState(player)
	local userId = player.UserId
	if not playerStates[userId] then
		local config = getPlayerConfig(player)
		playerStates[userId] = {
			isBlocking = false,
			blockOverload = 0,
			isStunned = false,
			currentStunType = nil,
			stunEndTime = 0,
			isInvincible = false, -- New state for invincibility
			originalWalkSpeed = 16, -- Default, will be updated on CharacterAdded
			blockLimit = config.BlockLimit or 30,
			blockBreakStunDuration = config.BlockBreakStunDuration or STUN_TYPES.True.Duration, -- Use True stun duration as default
		}
		-- Update original walkspeed when character loads
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				playerStates[userId].originalWalkSpeed = humanoid.WalkSpeed
			end
		end)
		if player.Character then -- For players already in game
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				playerStates[userId].originalWalkSpeed = humanoid.WalkSpeed
			end
		end
	end
	return playerStates[userId]
end

-- Public: Returns block state for UI or other systems
function CombatHandler.GetBlockState(player)
	local state = getPlayerState(player)
	return {
		isBlocking = state.isBlocking,
		blockOverload = state.blockOverload,
		blockLimit = state.blockLimit,
	}
end

-- Public: Set player's invincibility status
function CombatHandler.SetInvincible(player, isInvincible)
	local state = getPlayerState(player)
	state.isInvincible = isInvincible
	print(
		string.format(
			"[CombatHandler Server] Player %s invincibility set to %s (at %.4f)",
			player.Name,
			tostring(isInvincible),
			os.clock()
		)
	)
end

-- Public: Main entry for player-initiated combat
-- Updated to accept damage as the 3rd argument
function CombatHandler.HandleHitEvent(player, damage, targetCharacters, stunTypeName)
	local isValid, reason = CombatHandler.IsValidAttack(player, damage, targetCharacters)
	if not isValid then
		warn(string.format("Combat exploit attempt by %s: %s", player.Name, reason))
		return
	end

	local hitterCharacter = player.Character
	if not hitterCharacter then
		warn(string.format("Hitter character not found for player %s", player.Name))
		return
	end

	-- Use stunTypeName directly if provided, otherwise default to "Soft"
	stunTypeName = stunTypeName or "Soft"

	playerAttackCooldowns[player.UserId] = os.clock()

	for _, targetCharacter in ipairs(targetCharacters) do
		-- Corrected: Pass hitterCharacter and targetCharacter directly
		if targetCharacter and targetCharacter ~= hitterCharacter then
			CombatHandler.ProcessHit(hitterCharacter, targetCharacter, damage, stunTypeName)
		end
	end
end

-- Public: Call to clean up all combat state for a player
function CombatHandler.CleanupPlayerData(player)
	if player then
		playerAttackCooldowns[player.UserId] = nil
		playerDamagePerSecond[player.UserId] = nil
		-- Clean up all states managed by getPlayerState
		if playerStates[player.UserId] then
			playerStates[player.UserId] = nil
		end
		-- Clean up any active stun threads
		if stunThreads[player.UserId] then
			for stunType, thread in pairs(stunThreads[player.UserId]) do
				task.cancel(thread) -- Attempt to cancel the running thread
			end
			stunThreads[player.UserId] = nil
		end
		print(string.format("Cleaned up combat data for %s", player.Name))
	end
end

-- Public: Initialize all combat event listeners
function CombatHandler.Init()
	local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	local CombatRemotes = RemotesFolder:WaitForChild("Combat")
	local HitEvent = CombatRemotes:WaitForChild("HitEvent")

	-- Keep this print statement to confirm InvincibilityEvent is correctly required
	if InvincibilityEvent and InvincibilityEvent:IsA("RemoteEvent") then
		print(
			string.format(
				"[CombatHandler Init] InvincibilityEvent found on server: %s (Parent: %s)",
				InvincibilityEvent.Name,
				InvincibilityEvent.Parent.Name
			)
		)
	else
		warn("[CombatHandler Init] InvincibilityEvent is NOT a RemoteEvent or not found on server!")
	end

	HitEvent.OnServerEvent:Connect(function(player, damage, targetCharacters, stunTypeName)
		CombatHandler.HandleHitEvent(player, damage, targetCharacters, stunTypeName)
	end)

	-- Connect InvincibilityEvent
	InvincibilityEvent.OnServerEvent:Connect(function(player, duration, dashType) -- Added dashType parameter
		-- Sanitize duration input
		duration = math.max(0, tonumber(duration) or 0)
		dashType = type(dashType) == "string" and dashType or "unknown dash" -- Sanitize dashType
		-- Keep this print statement to confirm client-server communication
		print(
			string.format(
				"[CombatHandler Server] Received InvincibilityEvent for Player %s (Dash: %s) with duration %.2f (at %.4f)",
				player.Name,
				dashType,
				duration,
				os.clock()
			)
		)
		CombatHandler.SetInvincible(player, true)
		task.delay(duration, function()
			-- Only set to false if it's still the same invincibility state (no new invincibility applied)
			-- This simple check prevents a shorter invincibility from overriding a longer one if fired rapidly.
			-- For more complex scenarios (e.g., stacking invincibility), more robust state management would be needed.
			if playerStates[player.UserId] and playerStates[player.UserId].isInvincible then
				CombatHandler.SetInvincible(player, false)
				-- Keep this print statement to confirm invincibility end
				print(
					string.format(
						"[CombatHandler Server] Invincibility ended for Player %s (at %.4f)",
						player.Name,
						os.clock()
					)
				)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		CombatHandler.CleanupPlayerData(player)
	end)
	-- Keep this print statement for general initialization confirmation
	print("CombatHandler initialized.")
end

-- Validation: Checks if a player attack is allowed
-- Updated to accept damage as the 2nd argument
function CombatHandler.IsValidAttack(player, damage, targetCharacters)
	if not player or not player.Character then
		return false, "Invalid player"
	end
	local hitterCharacter = player.Character
	local hitterRootPart = hitterCharacter:FindFirstChild("HumanoidRootPart")
	if not hitterRootPart then
		return false, "No root part for hitter"
	end

	local playerState = getPlayerState(player)
	-- Prevent attack if player is stunned
	if playerState.isStunned then
		return false, "Player is stunned"
	end

	local currentTime = os.clock()
	local lastAttackTime = playerAttackCooldowns[player.UserId] or 0
	if currentTime - lastAttackTime < MIN_ATTACK_COOLDOWN then
		return false, "Attack too fast"
	end

	if #targetCharacters > MAX_TARGETS_PER_ATTACK then
		return false, "Too many targets"
	end

	for _, targetCharacter in ipairs(targetCharacters) do
		if targetCharacter and targetCharacter ~= hitterCharacter then
			local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
			if targetPlayer then
				local targetPlayerState = getPlayerState(targetPlayer)
				if targetPlayerState.isInvincible then
					return false, string.format("Target %s is invincible", targetPlayer.Name)
				end
			end

			local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
			if targetRootPart then
				local distance = (targetRootPart.Position - hitterRootPart.Position).Magnitude
				if distance > MAX_ATTACK_RANGE then
					return false, "Target too far"
				end
			else
				return false, "Target has no root part"
			end
		end
	end

	-- Damage is now directly passed, no need to look it up in DAMAGE_VALUES
	local totalDamage = damage * #targetCharacters
	if not playerDamagePerSecond[player.UserId] then
		playerDamagePerSecond[player.UserId] = { damage = 0, lastReset = currentTime }
	end
	local dpsData = playerDamagePerSecond[player.UserId]
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

-- Combat Hit Processing
-- The ProcessHit function handles applying damage, managing blocks, and initiating stuns based on combat interactions.
-- Damage/Block: Handles a single hit, applying damage or block overload
-- hitterCharacter: The character of the player dealing the hit
-- targetCharacter: The Character object of the target being hit
-- damage: The amount of damage to apply
-- stunTypeName: The name of the stun type to apply (e.g., "Soft", "Hard", "True")
function CombatHandler.ProcessHit(hitterCharacter, targetCharacter, damage, stunTypeName)
	local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
	if not targetHumanoid then
		return
	end

	local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
	-- Handle NPC targets separately as they don't have player states
	if not targetPlayer then
		targetHumanoid.Health = math.max(0, targetHumanoid.Health - damage)
		-- NPCs will always receive stun if damage is applied, as they don't block
		local stunDuration = STUN_TYPES[stunTypeName] and STUN_TYPES[stunTypeName].Duration or STUN_TYPES.Soft.Duration
		CombatHandler.ApplyStun(targetCharacter, stunTypeName, stunDuration)
		return
	end

	local playerState = getPlayerState(targetPlayer)

	-- TOP LEVEL INVINCIBILITY CHECK IN PROCESS HIT
	if playerState.isInvincible then
		-- Keep this print statement as it indicates a successful invincibility block
		print(
			string.format(
				"[CombatHandler Server] Target %s is invincible. No damage or stun applied (from ProcessHit). (at %.4f)",
				targetPlayer.Name,
				os.clock()
			)
		)
		return -- Exit early if invincible
	end
	-- Removed: Debug print to confirm if this path is taken when invincibility is false

	local appliedHealthDamage = damage
	-- Stun duration will be set based on block status
	local stunToApply = stunTypeName
	local stunDuration = STUN_TYPES[stunTypeName] and STUN_TYPES[stunTypeName].Duration or STUN_TYPES.Soft.Duration

	if playerState.isBlocking then
		local newOverload = playerState.blockOverload + damage
		-- Update playerState.blockOverload with the new value immediately
		playerState.blockOverload = newOverload

		-- Fire the visual event *before* checking for block break
		BlockOverloadVisualEvent:FireClient(targetPlayer, {
			blockOverload = playerState.blockOverload,
			blockLimit = playerState.blockLimit,
			isBlocking = playerState.isBlocking,
		})

		if newOverload >= playerState.blockLimit then
			-- Block broken!
			local excess = newOverload - playerState.blockLimit
			playerState.blockOverload = 0 -- Reset to 0 after visual event
			playerState.isBlocking = false
			appliedHealthDamage = excess -- Apply excess damage
			stunToApply = "True" -- Always apply True stun on block break
			stunDuration = playerState.blockBreakStunDuration -- Use specific block break stun duration
			BlockEvent:FireClient(targetPlayer, "Break") -- Explicitly fire "Break" event
			print(
				string.format(
					"[ProcessHit] Block broken for %s! Applying %s stun for %.2f, Excess damage: %.2f",
					targetPlayer.Name,
					stunToApply,
					stunDuration,
					excess
				)
			)
		else
			-- Successfully blocked, no health damage, no stun
			appliedHealthDamage = 0
			stunToApply = nil -- Explicitly set to nil to prevent stun
		end
	end

	if appliedHealthDamage > 0 then
		targetHumanoid.Health = math.max(0, targetHumanoid.Health - appliedHealthDamage)
	end

	-- Apply stun only if stunToApply is not nil (i.e., not a successful block)
	if stunToApply then
		CombatHandler.ApplyStun(targetCharacter, stunToApply, stunDuration)
	end
end

-- Stun Management
-- The ApplyStun function handles applying and removing stun effects on characters, differentiating between players and NPCs.
-- Status: Applies a temporary stun to a character
-- character: The character to apply the stun to
-- stunTypeName: The name of the stun type (e.g., "Soft", "Hard", "True")
-- duration: How long the stun should last
function CombatHandler.ApplyStun(character, stunTypeName, duration)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	local player = Players:GetPlayerFromCharacter(character)
	-- If it's an NPC, it won't have a player object, so we apply stun directly without playerState management
	if not player then
		local originalWalkSpeed = humanoid.WalkSpeed
		local stunProperties = STUN_TYPES[stunTypeName] or STUN_TYPES.Soft
		humanoid.WalkSpeed = originalWalkSpeed * stunProperties.WalkSpeedMultiplier

		-- Anchor NPC during True stun
		if stunTypeName == "True" and rootPart then
			rootPart.Anchored = true
		end

		task.delay(duration, function()
			if humanoid and humanoid.Parent == character then -- Check if humanoid still exists in the character
				humanoid.WalkSpeed = originalWalkSpeed
				-- Unanchor NPC after True stun
				if stunTypeName == "True" and rootPart and rootPart.Parent == character then
					rootPart.Anchored = false
				end
			end
		end)
		return
	end

	local playerState = getPlayerState(player)

	-- Removed: Debug print to check invincibility state right before the check
	-- Keep the invincibility check itself
	if playerState.isInvincible then
		-- Keep this print statement as it indicates a successful invincibility block
		print(
			string.format("[ApplyStun] Player %s is invincible. Stun type '%s' not applied.", player.Name, stunTypeName)
		)
		return
	end

	local stunProperties = STUN_TYPES[stunTypeName]

	if not stunProperties then
		warn(string.format("[ApplyStun] Unknown stun type: %s. Applying default stun.", stunTypeName))
		stunTypeName = "Soft" -- Fallback to soft stun
		stunProperties = STUN_TYPES.Soft
	end

	-- Cancel any existing stun task for this player if a new one is applied
	-- We need to check if there's an active stun thread for the currentStunType
	if
		playerState.currentStunType
		and stunThreads[player.UserId]
		and stunThreads[player.UserId][playerState.currentStunType]
	then
		task.cancel(stunThreads[player.UserId][playerState.currentStunType])
		-- Ensure rootPart is unanchored if the previous stun was True
		if playerState.currentStunType == "True" and rootPart and rootPart.Anchored then
			rootPart.Anchored = false
			print(string.format("[ApplyStun] Unanchored %s (previous True stun cancelled).", player.Name))
		end
		stunThreads[player.UserId][playerState.currentStunType] = nil
		print(string.format("[ApplyStun] Cancelled previous %s stun for %s.", playerState.currentStunType, player.Name))
	end
	-- Reset stun state before applying new one
	playerState.isStunned = false
	playerState.currentStunType = nil
	playerState.stunEndTime = 0
	humanoid.WalkSpeed = playerState.originalWalkSpeed -- Reset speed before applying new stun speed
	if rootPart and rootPart.Anchored then -- Ensure rootPart is unanchored if it was mistakenly anchored
		rootPart.Anchored = false
	end

	-- Apply stun effects to player state
	playerState.isStunned = true
	playerState.currentStunType = stunTypeName
	playerState.stunEndTime = os.clock() + duration
	humanoid.WalkSpeed = playerState.originalWalkSpeed * stunProperties.WalkSpeedMultiplier

	-- Anchor HumanoidRootPart for True stun
	if stunTypeName == "True" and rootPart then
		rootPart.Anchored = true
		print(string.format("[ApplyStun] Anchored HumanoidRootPart for %s (True stun).", player.Name))
	end

	print(string.format("[ApplyStun] Applied %s stun to %s for %.2f seconds.", stunTypeName, player.Name, duration))

	-- Schedule stun removal
	local stunThread = task.spawn(function()
		task.wait(duration)
		if humanoid and humanoid.Parent and playerStates[player.UserId] then -- Check if player/character still exists
			-- Only remove stun if this is still the active stun and its duration has passed
			if
				playerStates[player.UserId].currentStunType == stunTypeName
				and os.clock() >= playerStates[player.UserId].stunEndTime
			then
				humanoid.WalkSpeed = playerStates[player.UserId].originalWalkSpeed
				playerStates[player.UserId].isStunned = false
				playerStates[player.UserId].currentStunType = nil
				playerStates[player.UserId].stunEndTime = 0
				print(string.format("[ApplyStun] %s stun removed from %s.", stunTypeName, player.Name))

				-- Unanchor HumanoidRootPart after True stun
				if stunTypeName == "True" and rootPart and rootPart.Parent == character then
					rootPart.Anchored = false
					print(
						string.format("[ApplyStun] Unanchored HumanoidRootPart for %s (True stun ended).", player.Name)
					)
				end
			end
		end

		local targetPlayer = Players:GetPlayerFromCharacter(character)
		StunEvent:FireClient(targetPlayer, stunTypeName, duration)

		-- Clean up the thread reference after it completes
		if stunThreads[player.UserId] then
			stunThreads[player.UserId][stunTypeName] = nil
		end
	end)

	-- Store thread to manage it
	stunThreads[player.UserId] = stunThreads[player.UserId] or {}
	stunThreads[player.UserId][stunTypeName] = stunThread
end

-- Block: Handles block start/stop events from the client
BlockEvent.OnServerEvent:Connect(function(player, action)
	local state = getPlayerState(player)
	if action == "Start" then
		state.isBlocking = true
	elseif action == "Stop" then
		state.isBlocking = false
	end
	-- This fires immediately on start/stop, showing the current state
	BlockOverloadVisualEvent:FireClient(player, {
		blockOverload = state.blockOverload,
		blockLimit = state.blockLimit,
		isBlocking = state.isBlocking,
	})
end)

-- General Damage Block Overload
-- This section handles general damage redirection to block overload if BLOCK_OVERLOAD_FOR_ALL_DAMAGE is enabled.
-- Block: Redirects all damage to block overload if enabled and player is blocking
local blockOverloadConnections = {}
local function setupBlockOverloadForGeneralDamage(player)
	if not BLOCK_OVERLOAD_FOR_ALL_DAMAGE then
		return
	end

	local function onCharacterAdded(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		local lastHealth = humanoid.Health -- Initialize lastHealth for this character instance

		-- Disconnect existing connection if character respawns
		if blockOverloadConnections[player.UserId] then
			blockOverloadConnections[player.UserId]:Disconnect()
			blockOverloadConnections[player.UserId] = nil
		end

		local conn
		conn = humanoid.HealthChanged:Connect(function(newHealth)
			local state = getPlayerState(player)

			-- Priority 1: Invincibility
			-- If the player is invincible, prevent ANY health reduction.
			if state.isInvincible then
				-- If health decreased while invincible, revert it
				if newHealth < lastHealth then
					humanoid.Health = lastHealth
					return
				end
			end

			-- Priority 2: Blocking general damage (only if not invincible, not stunned, and feature enabled)
			-- This part handles damage absorption by block overload.
			if
				not state.isInvincible
				and not state.isStunned
				and state.isBlocking
				and BLOCK_OVERLOAD_FOR_ALL_DAMAGE
			then
				local delta = lastHealth - newHealth
				if delta > 0 then -- If health decreased
					state.blockOverload = state.blockOverload + delta
					humanoid.Health = lastHealth -- Revert health change, absorbed by block

					BlockOverloadVisualEvent:FireClient(player, {
						blockOverload = state.blockOverload,
						blockLimit = state.blockLimit,
						isBlocking = state.isBlocking,
					})

					if state.blockOverload >= state.blockLimit then
						state.isBlocking = false
						state.blockOverload = 0
						local blockBreakStunDuration = state.blockBreakStunDuration
						BlockEvent:FireClient(player, "Break")
						CombatHandler.ApplyStun(character, "True", blockBreakStunDuration)
						print(
							string.format(
								"[GeneralDamage] Block broken for %s! Stun: %.2f",
								player.Name,
								blockBreakStunDuration
							)
						)
					end
					lastHealth = humanoid.Health -- Update lastHealth after block processing
					return -- Handled by block, no further health processing needed for this delta
				end
			end

			-- If not invincible and not blocked, then the health change is allowed to persist
			lastHealth = newHealth -- Update lastHealth to the new, allowed health
		end)
		blockOverloadConnections[player.UserId] = conn

		-- When character dies or is removed, disconnect the health changed event
		character.AncestryChanged:Connect(function(_, parent)
			if not parent and blockOverloadConnections[player.UserId] then
				blockOverloadConnections[player.UserId]:Disconnect()
				blockOverloadConnections[player.UserId] = nil
			end
		end)
	end
	-- Initial setup for existing characters or when a player is added
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end

if BLOCK_OVERLOAD_FOR_ALL_DAMAGE then
	Players.PlayerAdded:Connect(function(player)
		setupBlockOverloadForGeneralDamage(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		setupBlockOverloadForGeneralDamage(player)
	end
end

-- UI Synchronization
-- Handles initial UI setup and continuous block overload reduction for visual feedback.
-- UI: Send initial block overload state to client on join
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Wait()
	local state = getPlayerState(player)
	BlockOverloadVisualEvent:FireClient(player, {
		blockOverload = 0,
		blockLimit = state.blockLimit,
		isBlocking = false,
	})
end)

-- Block overload reduction loop
local function startBlockOverloadReduction()
	task.spawn(function()
		while true do
			for userId, state in pairs(playerStates) do
				-- Block overload should decay as long as it's above zero, regardless of blocking status
				if state.blockOverload > 0 then
					local player = Players:GetPlayerByUserId(userId)
					if player then
						local reduction = BLOCK_OVERLOAD_REDUCTION_PER_SECOND * BLOCK_OVERLOAD_REDUCTION_INTERVAL
						local blockLimit = state.blockLimit -- Use player's block limit
						local before = state.blockOverload
						state.blockOverload = math.max(0, state.blockOverload - reduction)
						-- Only fire event if there's a significant change to avoid spamming
						if math.abs(state.blockOverload - before) > 0.01 then
							BlockOverloadVisualEvent:FireClient(player, {
								blockOverload = state.blockOverload,
								blockLimit = blockLimit,
								isBlocking = state.isBlocking, -- Still send current blocking status
							})
						end
					end
				end
			end
			task.wait(BLOCK_OVERLOAD_REDUCTION_INTERVAL)
		end
	end)
end

startBlockOverloadReduction()

return CombatHandler
