--[[
	An interactive grass module utilizing skinned meshes
	Made by xander22 (youtube.com/@xand3r22, x.com/x4nder22)
	
	CREDITS:
	
	Octree by Quenty
]]

-- Modules
local Octree = require(script.Parent.Octree.Octree)
local utils = require(script.Parent.SkinnedGrassUtils)

-- Services
local TweenService = game:GetService("TweenService")

-- default settings, can be overriden at runtime with UpdateSettings()
local DEFAULT_SETTINGS = {
	RenderDistanceEnabled = true, -- If grass should be rendered in/out
	RenderDistance = 60, -- Distance at which grass is fully rendered out --150
	RenderInAnimation = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), -- TweenInfo to apply to bones rendering in. Set to nil for no animation (more performant)
	RenderOutAnimation = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), -- TweenInfo to apply to bones rendering out. Set to nil for no animation (more performant)
	RenderOutOffset = CFrame.new(0, -3, 0), -- Offset for bones when rendering in/out
	MeshStorage = nil, -- Folder to store meshes that are rendered out. By default creates a folder in ReplicatedStorage

	CollisionsEnabled = true, -- If grass should be simulated with collisions. To disable collisions, set this bool to false rather than setting collision distance to 0
	CollisionDistance = 20, -- Distance at which collisions are simulated
	CollisionRadiusInner = 4, -- Radius around collision where bones are fully displaced
	CollisionRadiusOuter = 6, -- Radius around collision where the displacement effect ends
	CollisionAngle = 35, -- Angle of the displacement effect
	CollisionTranslation = Vector3.new(0, 0, 0), -- Position offset of the displacement effect
	CollisionReturnDelay = 0, -- Time that the grass stays displaced before bouncing back (begins after collision stops)
	CollisionReturnInfo = TweenInfo.new(1.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), -- TweenInfo for the return animation

	WindEnabled = true, -- If grass should be simulated with wind. To disable wind, set this to false rather than setting wind distance to 0
	WindDistanceInner = 25, -- Distance at which wind is simulated with max frame rate
	WindDistanceOuter = 60, -- Distance at which wind is simulated with min frame rate
	WindFramerateInner = 0.9, -- Frame rate for wind in inner range (1 = 100% frames, 0.5 = 50% frames, etc)
	WindFramerateOuter = 0.3, -- Frame rate for wind in outer range
	WindNoiseSize = 3, -- Size for wind noise calculations
	WindNoiseIntensity = 1.05, -- Intensity for wind noise calculations
	UseGlobalWind = false, -- When set to true, overrides WindDirection, WindSpeed, WindAngle and WindTranslation settings with Roblox's wind
	WindDirection = Vector3.new(1, 0, 1), -- Direction of the wind effect
	WindSpeed = 8, -- Speed of the wind effect
	WindAngleMin = 5, -- Min angle of the wind effect
	WindAngleMax = 25, -- Max angle of the wind effect
	WindTranslationMin = Vector3.new(0, 0, 0), -- Min position offset of the wind effect
	WindTranslationMax = Vector3.new(0, 0, 0), -- Max position offset of the wind effect
}

local SkinnedGrass = {}
SkinnedGrass.__index = SkinnedGrass

-- initialize new grass object
function SkinnedGrass.new(initialSettings)
	local obj = {
		Settings = {},
		SkinnedMeshesRenderedIn = {},
		MeshParents = {},
		MeshTweenOuts = {},
		MeshOctree = {},
		BoneOctree = Octree.new(),
		DisplaceBones = {},
		ReturnBones = {},
		FrameCountInner = 1,
		FrameCountOuter = 1,
	}
	setmetatable(obj, SkinnedGrass)

	obj.MeshOctree = Octree.new()

	obj.Settings = initialSettings or {}
	for i, v in DEFAULT_SETTINGS do
		if not obj.Settings[i] then
			obj.Settings[i] = v
		end
	end

	return obj
end

-- updates settings. 'settingsTable' argument should have the same format as DEFAULT_SETTINGS. Leave arguments empty to reset settings to default
function SkinnedGrass:UpdateSettings(settingsTable: {})
	if self.Settings == nil then
		self.Settings = {}
	end

	if settingsTable == nil then
		for i, v in DEFAULT_SETTINGS do
			self.Settings[i] = v
		end
		return
	end
	assert(type(settingsTable) == "table", "Expected table as parameter")

	for i, v in DEFAULT_SETTINGS do
		if settingsTable[i] ~= nil then
			self.Settings[i] = settingsTable[i]
		elseif self.Settings[i] == nil then
			self.Settings[i] = v
		end
	end
end

-- adds meshes to grass object
function SkinnedGrass:AddMeshes(skinnedMeshModels: { Model })
	if typeof(skinnedMeshModels) ~= "table" then
		warn("AddMeshes() parameter must be a table")
		return
	end

	if self.MeshFolder == nil then
		local folder = game.ReplicatedStorage:FindFirstChild("SkinnedGrass_Storage")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "SkinnedGrass_Storage"
			folder.Parent = game.ReplicatedStorage
		end
		self.MeshFolder = folder
	end

	for _, model in skinnedMeshModels do
		if not model:IsA("Model") then
			warn(model, "is not a model")
			continue
		end
		if self.MeshParents[model] then
			continue
		end -- check if model has already been added to simulation
		local meshPart = model:FindFirstChildOfClass("MeshPart")
		if not meshPart then -- yield thread if meshpart hasn't loaded
			local timeout = 0
			while not meshPart and timeout < 5 do
				meshPart = model:FindFirstChildOfClass("MeshPart")
				timeout += task.wait()
			end
			if not meshPart then
				warn(model, "does not have a loaded mesh part. Consider setting ModelStreamingMode to atomic")
				continue
			end
		end
		-- cache the bones for looping
		local bones = meshPart:GetChildren()
		-- create origin bone for transforming bones en masse
		local originBone = Instance.new("Bone")
		originBone.Parent = meshPart
		originBone.WorldCFrame = meshPart.CFrame
		originBone.Name = "SkinnedGrass_Origin"
		-- loop through each bone and reparent to origin bone
		for _, bone in bones do
			if not bone:IsA("Bone") then
				continue
			end
			self.BoneOctree:CreateNode(bone.TransformedWorldCFrame.Position, bone)
			bone.Parent = originBone
		end
		-- set origin bone to below skinned mesh for fade in
		originBone.Transform = CFrame.new(0, -3, 0)
		self.MeshOctree:CreateNode(originBone.WorldCFrame.Position, meshPart)
		-- store mesh in replicated storage until needed (bones aren't calculated when not in workspace)
		self.MeshParents[model] = model.Parent
		model.Parent = self.MeshStorage
	end
end

-- main logic of the module, called every interval. Put in RunService.RenderStepped for smoothest simulation
-- targetPos = position the simulation is based around (ie the player's position)
-- collisions = table of information for the displacement effect
-- each index of collisions should be a Vector3 or a table with the following format: {collisionPos, customSettings}
-- customSettings is a table of custom displacement settings for that collision, follows the same format as DEFAULT_SETTINGS
function SkinnedGrass:Step(deltaTime: number, collisions: {}, targetPos: Vector3)
	if targetPos == nil then -- if no target pos center simulation around player character
		local char = game.Players.LocalPlayer.Character
		if char then
			targetPos = char.PrimaryPart.Position
		else
			return
		end
	end
	local settingsTable = self.Settings
	local meshesToRemove = table.clone(self.SkinnedMeshesRenderedIn)
	if settingsTable.RenderDistanceEnabled then
		local skinnedMeshesInRenderDistance = self.MeshOctree:RadiusSearch(targetPos, settingsTable.RenderDistance)
		for _, v in skinnedMeshesInRenderDistance do
			if table.find(self.SkinnedMeshesRenderedIn, v) == nil then
				table.insert(self.SkinnedMeshesRenderedIn, v)
				--v.Parent.Parent = workspace
				local model = v:FindFirstAncestorOfClass("Model")
				model.Parent = self.MeshParents[model]
				--print("spawn mesh", v)
				if settingsTable.RenderInAnimation then
					TweenService
						:Create(
							v.SkinnedGrass_Origin,
							settingsTable.RenderInAnimation,
							{ Transform = CFrame.new(0, 0, 0) }
						)
						:Play()
				else
					v.SkinnedGrass_Origin.Transform = CFrame.new(0, 0, 0)
				end
			end
			table.remove(meshesToRemove, table.find(meshesToRemove, v))
		end
		for _, v in meshesToRemove do
			table.remove(self.SkinnedMeshesRenderedIn, table.find(self.SkinnedMeshesRenderedIn, v))
			if settingsTable.RenderOutAnimation then
				TweenService:Create(
					v.SkinnedGrass_Origin,
					settingsTable.RenderOutAnimation,
					{ Transform = settingsTable.RenderOutOffset }
				):Play()
				table.insert(self.MeshTweenOuts, v.SkinnedGrass_Origin)
			else
				local model = v:FindFirstAncestorOfClass("Model")
				model.Parent = settingsTable.MeshStorage
			end
		end
		for i, v in self.MeshTweenOuts do
			if (v.Transform.Position - settingsTable.RenderOutOffset.Position).Magnitude <= 0 then
				table.remove(self.MeshTweenOuts, i)
				v:FindFirstAncestorOfClass("Model").Parent = settingsTable.MeshStorage
			end
		end
	end

	local transformedBones = {}

	local windDir = game.Workspace.GlobalWind
	if not settingsTable.UseGlobalWind then
		windDir = settingsTable.WindDirection
	end
	if windDir.Magnitude == 0 then
		windDir = Vector3.new(0, 0, 1)
	end
	local windIntensity = math.min(game.Workspace.GlobalWind.Magnitude, 20)
	self.FrameCountInner += 1
	if self.FrameCountInner >= 1 / settingsTable.WindFramerateInner then
		self.FrameCountInner = 1
	end
	self.FrameCountOuter += 1
	if self.FrameCountOuter >= 1 / settingsTable.WindFramerateOuter then
		self.FrameCountOuter = 1
	end

	if self.WindAnimation == nil or self.WindAnimation >= 1 then
		self.WindAnimation = 0
	end
	local windSpeed = 1 + windIntensity / 20
	if not settingsTable.UseGlobalWind then
		windSpeed = 1 + settingsTable.WindSpeed / 20
	end
	self.WindAnimation += deltaTime * windSpeed
	local minAngle = 0
	local maxAngle = 0
	local minTranslation = Vector3.zero
	local maxTranslation = Vector3.zero
	if self.Settings.WindEnabled then
		minAngle = math.max(windIntensity * 2, -2)
		maxAngle = math.max(windIntensity * 3, 2)
		if not settingsTable.UseGlobalWind then
			minAngle = settingsTable.WindAngleMin
			maxAngle = settingsTable.WindAngleMax
			minTranslation = settingsTable.WindTranslationMin
			maxTranslation = settingsTable.WindTranslationMax
		end
		if self.FrameCountInner == 1 then
			local bonesInWindDistance = self.BoneOctree:RadiusSearch(targetPos, self.Settings.WindDistanceInner)
			for i = 1, #bonesInWindDistance do
				local bone = bonesInWindDistance[i]
				local windCFrame = utils.CalculateWindAtPoint(
					bone,
					self.WindAnimation,
					windDir,
					minAngle,
					maxAngle,
					minTranslation,
					maxTranslation,
					settingsTable.WindNoiseSize,
					settingsTable.WindNoiseIntensity
				)
				bone.Transform = windCFrame
			end
		end
		if self.FrameCountOuter == 1 then
			local bonesInWindDistanceOuter = self.BoneOctree:RadiusSearch(targetPos, self.Settings.WindDistanceOuter)
			for i = 1, #bonesInWindDistanceOuter do
				local bone = bonesInWindDistanceOuter[i]
				local windCFrame = utils.CalculateWindAtPoint(
					bone,
					self.WindAnimation,
					windDir,
					minAngle,
					maxAngle,
					minTranslation,
					maxTranslation,
					settingsTable.WindNoiseSize,
					settingsTable.WindNoiseIntensity
				)
				bone.Transform = windCFrame
			end
		end
	end

	if settingsTable.CollisionsEnabled and collisions then
		local collisionsInRange = {}
		for _, collision in collisions do
			local pos, customSettings
			if typeof(collision) == "table" then
				pos = collision[1]
				customSettings = collision[2]
			else
				pos = collision
				customSettings = {}
			end
			if (pos - targetPos).Magnitude > settingsTable.CollisionDistance then
				continue
			end -- outside of the collision sim distance
			local collisionSettings = table.clone(settingsTable)
			for key, value in customSettings do -- custom settings
				if collisionSettings[key] then
					collisionSettings[key] = value
				end
			end

			local bonesInCollisionDistance =
				self.BoneOctree:RadiusSearch(pos, collisionSettings.CollisionRadiusOuter - 0.1) --slight offset to prevent return starting instantly
			local displaceFadeRange: number = collisionSettings.CollisionRadiusOuter
				- collisionSettings.CollisionRadiusInner
			for _, bone in bonesInCollisionDistance do
				table.insert(transformedBones, bone)

				local displaceInfo = self.DisplaceBones[bone]
				if displaceInfo == nil then --first time calculating, set target rotation and displace percent
					displaceInfo = {}
					displaceInfo[1] = collisionSettings --settings
					displaceInfo[2] = self.ReturnBones[bone] and self.ReturnBones[bone][2] or 0 --displace percent

					local directionToKnock = (bone.WorldCFrame.Position - pos).Unit
					local localKnockDirection = bone.CFrame:VectorToObjectSpace(directionToKnock)

					-- Preserve the current Y rotation, only affect X and Z
					local _, currentYRotation, _ = bone.Transform:ToOrientation() -- Extract the Y rotation

					local tiltDirection = Vector3.new(localKnockDirection.X, 0, localKnockDirection.Z).Unit

					-- Knock the bone over by tilting it based on the knock intensity
					local tiltAngle = math.rad(settingsTable.CollisionAngle)
					local newXRotation = tiltAngle * tiltDirection.Z -- Tilt along X based on Z direction
					local newZRotation = -tiltAngle * tiltDirection.X -- Tilt along Z based on X direction
					local newTranslation = settingsTable.CollisionTranslation
					-- Set the new orientation while preserving the Y rotation
					local targetCFrame = CFrame.new(newTranslation)
						* CFrame.Angles(newXRotation, currentYRotation, newZRotation)
					displaceInfo[4] = targetCFrame
				end

				-- calculate displacement percentage by checking where the bone is at between the displacement radius inner and displacement radius outer
				local distFromOrigin: number = (bone.WorldCFrame.Position - pos).Magnitude
				local range =
					math.min(1 - (distFromOrigin - collisionSettings.CollisionRadiusInner) / displaceFadeRange, 1)
				if range > displaceInfo[2] then --displace amount can only go up, not down (out animation handled by return table)
					displaceInfo[2] = range --percent displaced, 0 = no displacement, 1 = full displacement
				end
				displaceInfo[3] = range
				self.DisplaceBones[bone] = displaceInfo
				self.ReturnBones[bone] = nil
			end
		end

		for bone, displaceInfo in self.DisplaceBones do
			local origRotX, origRotY, origRotZ = displaceInfo[4]:ToEulerAnglesYXZ()
			local newRot = CFrame.fromEulerAnglesXYZ(
				origRotX * displaceInfo[2],
				origRotY * displaceInfo[2],
				origRotZ * displaceInfo[2]
			)
			local newPos = CFrame.new(
				displaceInfo[4].Position.X * displaceInfo[2],
				displaceInfo[4].Position.Y * displaceInfo[2],
				displaceInfo[4].Position.Z * displaceInfo[2]
			)

			local windRot = utils.CalculateWindAtPoint(
				bone,
				self.WindAnimation,
				windDir,
				minAngle,
				maxAngle,
				minTranslation,
				maxTranslation,
				settingsTable.WindNoiseSize,
				settingsTable.WindNoiseIntensity
			)
			bone.Transform = CFrame.new(Vector3.zero) * windRot:Lerp(newRot * newPos, displaceInfo[2])

			if displaceInfo[3] <= 0 or table.find(transformedBones, bone) == nil then --out of range, do return
				local returnInfo = {}
				returnInfo[1] = displaceInfo[1] --settings
				returnInfo[2] = displaceInfo[2] --percent displaced
				returnInfo[3] = tick() --time of displacement leaving range
				returnInfo[4] = bone.Transform -- cframe to lerp from
				self.ReturnBones[bone] = returnInfo
				self.DisplaceBones[bone] = nil
				continue
			end
		end

		for bone, returnInfo in self.ReturnBones do
			local collisionSettings = returnInfo[1]
			local timeSinceCollision = tick() - returnInfo[3]
			if timeSinceCollision < collisionSettings.CollisionReturnDelay then
				local windRot = utils.CalculateWindAtPoint(
					bone,
					self.WindAnimation,
					windDir,
					minAngle,
					maxAngle,
					minTranslation,
					maxTranslation,
					settingsTable.WindNoiseSize,
					settingsTable.WindNoiseIntensity
				)
				bone.Transform = returnInfo[4]
				continue
			end
			local returnTweenInfo: TweenInfo = collisionSettings.CollisionReturnInfo
			if timeSinceCollision >= collisionSettings.CollisionReturnDelay + returnTweenInfo.Time then
				self.ReturnBones[bone] = nil
				continue
			end

			local percentReturned = (timeSinceCollision - collisionSettings.CollisionReturnDelay) / returnTweenInfo.Time
			local tweenValue =
				TweenService:GetValue(percentReturned, returnTweenInfo.EasingStyle, returnTweenInfo.EasingDirection)
			returnInfo[2] = 1 - tweenValue
			local windRot = utils.CalculateWindAtPoint(
				bone,
				self.WindAnimation,
				windDir,
				minAngle,
				maxAngle,
				minTranslation,
				maxTranslation,
				settingsTable.WindNoiseSize,
				settingsTable.WindNoiseIntensity
			)
			local newRot = returnInfo[4]:lerp(windRot, tweenValue)

			bone.Transform = CFrame.new(Vector3.zero) * newRot
		end
	end
end

return SkinnedGrass
