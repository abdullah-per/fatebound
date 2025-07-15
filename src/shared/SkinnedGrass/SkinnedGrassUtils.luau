local module = {}

local TweenService = game:GetService("TweenService")

-- wind
local function Noise(x, y, z, size, intensity)
	size = size or 1
	intensity = intensity or 1

	local scaledX = x / size
	local scaledY = y / size
	local scaledZ = z / size

	local noiseValue = math.noise(scaledX, scaledY, scaledZ) * intensity

	return noiseValue
end
function module.CalculateWindAtPoint(
	bone: Bone,
	animationPercent: number,
	windDirection: Vector3,
	minAngle: number,
	maxAngle: number,
	minTranslation: Vector3,
	maxTranslation: Vector3,
	windSize: number,
	windIntensity: number
)
	local noise = Noise(bone.WorldCFrame.Position.X, 0, bone.WorldCFrame.Position.Z, windSize, windIntensity)
	local windAnimationLooped = 1 - math.abs(((animationPercent + noise) % 1) * 2 - 1)
	local windIntensity = minAngle
		+ (maxAngle - minAngle)
			* TweenService:GetValue(windAnimationLooped, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local parentRotation = bone.Parent.Parent.CFrame
	local modifiedWindDirection = parentRotation:VectorToObjectSpace(windDirection) -- convert wind direction to skinned mesh local space
	local localWindDirection = bone.CFrame:VectorToObjectSpace(modifiedWindDirection)
	local tiltDirection = Vector3.new(localWindDirection.X, 0, localWindDirection.Z).Unit

	-- Knock the bone over by tilting it based on the knock intensity
	local tiltAngle = math.rad(windIntensity)
	local newXRotation = tiltAngle * tiltDirection.Z -- Tilt along X based on Z direction
	local newZRotation = -tiltAngle * tiltDirection.X -- Tilt along Z based on X direction

	local targetOrientation = CFrame.Angles(newXRotation, 0, newZRotation)
	local targetTranslation = CFrame.new(
		minTranslation
			+ (maxTranslation - minTranslation)
				* TweenService:GetValue(windAnimationLooped, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	)
	return targetOrientation * targetTranslation
end

return module
