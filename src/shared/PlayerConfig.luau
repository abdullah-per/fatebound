local PlayerConfig = {}

-- Default configuration values (can be extended for per-player customization)
PlayerConfig.Defaults = {
	WalkSpeed = 16,
	RunSpeed = 24,
	DashCharges = 3,
	MaxDashCharges = 3,
	DashRechargeTime = 1,
	DashDuration = 0.4,
	SideDashDistance = 4,
	FrontDashDistance = 8,
	FrontDashMaxDistance = 30,
	BackDashDistance = 8,

	-- Combat configs (add as needed)
	LightAttackDamage = 10,
	HeavyAttackDamage = 20,

	BlockLimit = 40, -- Maximum block overload before breaking
	BlockOverloadDecay = 5, -- Overload decay per second when not blocking
	BlockBreakStunDuration = 1, -- Stun duration in seconds after block break

	LightAttackComboWindow = 1, -- seconds
	LightAttackMaxCombo = 2,
	LightAttackDetectionRange = 4, -- studs
	LightAttackDetectionSize = Vector3.new(4, 4, 4),
	HeavyAttackDetectionRange = 4, -- studs
	HeavyAttackDetectionSize = Vector3.new(4, 4, 4),

	-- Block overload reduction config
	BlockOverloadReductionPerSecond = 5, -- How much block overload is reduced per second when not blocking

	-- Climbing configs
	ClimbMaxStamina = 100,
	ClimbStaminaDrainPerSecond = 10, -- while moving
	ClimbStaminaJumpCost = 20,
	ClimbAttachAngleMin = 80, -- degrees
	ClimbAttachAngleMax = 120, -- degrees
	ClimbAttachDistance = 3, -- studs
	ClimbMoveSpeed = 10, -- studs/sec
	ClimbJumpBoost = 15, -- upward velocity
}

-- Function to get config for a player (can be extended for datastore)
function PlayerConfig:GetForPlayer(player)
	-- In the future, fetch from datastore here
	return self.Defaults
end

return PlayerConfig
