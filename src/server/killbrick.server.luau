--[[
    Kill Brick Script
    =================

    Server-side script for a killbrick that integrates with the CombatHandler.
    Instead of directly dealing damage, it calls CombatHandler.ProcessHit
    to allow the block overload system to intercept and handle damage
    if a player is currently blocking.

    Place this script inside a Part that you want to function as a killbrick.

    @author Fatebound Team
    @version 1.0.0
--]]

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Configuration
local KILL_BRICK_DAMAGE = 6.5 -- Damage dealt by the killbrick per touch
local ATTACK_TYPE = "KillBrickDamage" -- A descriptive attack type for logging/future use

--// Get the CombatHandler module
-- Ensure the path to your CombatHandler is correct
local CombatHandler = require(script.Parent.Handlers.CombatHandler) -- Adjust path if necessary

--// Reference to the killbrick part itself
local killBrick = workspace.Killbrick

--// Debounce to prevent multiple hits from a single touch
local debounce = {} -- [character] = true/false

--// Function to handle when something touches the killbrick
local function onTouch(otherPart)
	-- Check if the touched part is part of a character's humanoid
	local character = otherPart.Parent
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end -- Only process if it's a living humanoid

	-- Prevent multiple hits from the same touch event using debounce
	if debounce[character] then
		return
	end
	debounce[character] = true

	-- Get the player associated with the character, if it's a player
	local player = Players:GetPlayerFromCharacter(character)

	-- Call CombatHandler.ProcessHit to apply damage.
	-- For a killbrick, there isn't a "hitter character," so we pass nil.
	-- The CombatHandler.ProcessHit function is designed to handle this.
	-- It will check if 'character' (the target) is a player and if they are blocking.
	-- If blocking, it will increase block overload; otherwise, it will apply health damage.
	CombatHandler.ProcessHit(nil, character, KILL_BRICK_DAMAGE, ATTACK_TYPE)

	-- Remove from debounce after a short delay to allow re-hitting after leaving/re-entering
	task.delay(0.5, function()
		debounce[character] = nil
	end)
end

--// Connect the touch event
killBrick.Touched:Connect(onTouch)

print("Kill brick script initialized for:", killBrick.Name)
