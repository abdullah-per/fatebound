--// Ragdoll
local ragdoll = {}

local anchorRagdoll = function(doll)
	for _, part in ipairs(doll:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then --Keeping HRP for later anchoring
			part.Anchored = true
		end
	end
end

ragdoll.EnableRagdoll = function(character, velocityVector, velocityStrength)
	--
	character.Humanoid.PlatformStand = true

	--shirt and pants...
	local description = character.Humanoid:GetAppliedDescription()

	character.Archivable = true
	local doll = character:clone()
	doll.Name = character.Name .. "_ragdoll" .. math.random(1, 10000)
	doll.Parent = workspace

	character.Archivable = false
	character:Destroy()

	local humanoid = doll.Humanoid
	humanoid:ApplyDescription(description)

	humanoid.PlatformStand = true
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	--Doing it on a seperate thread for spectating purposes
	task.spawn(function()
		--
		for _, motor in ipairs(doll:GetDescendants()) do
			if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
				local att0 = Instance.new("Attachment")
				att0.CFrame = motor.C0
				att0.Parent = motor.Part0
				att0.Name = motor.Name .. "Attachment0"

				local att1 = Instance.new("Attachment")
				att1.CFrame = motor.C1
				att1.Parent = motor.Part1
				att1.Name = motor.Name .. "Attachment1"

				local bsConstraint = Instance.new("BallSocketConstraint")
				bsConstraint.Attachment0 = att0
				bsConstraint.Attachment1 = att1
				bsConstraint.Parent = motor.Parent

				bsConstraint.LimitsEnabled = true
				bsConstraint.UpperAngle = 60
				bsConstraint.Restitution = 60
				bsConstraint.TwistLimitsEnabled = true

				motor:Destroy()
			end
		end

		task.wait(0.15)

		--
		for _, part in ipairs(doll:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then --Keeping HRP for later anchoring
				part.CanCollide = true
				part.Anchored = false
				part.Massless = false

				if part.Name == "Torso" then
					if not velocityVector then
						velocityVector = Vector3.new(math.random(), math.random(), math.random())
					end
					if not velocityStrength then
						velocityStrength = 50
					end

					part.Velocity = velocityVector.Unit * velocityStrength
				end
			end
		end

		-- task.wait(0.5)
		-- anchorRagdoll(doll)
	end)

	return doll
end

return ragdoll
