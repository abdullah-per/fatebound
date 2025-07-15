local AnimationHandler = {}
AnimationHandler.__index = AnimationHandler

function AnimationHandler.new(Rig, AnimationsFolder, getDescendants)
	local self = setmetatable({}, AnimationHandler)

	self.Rig = Rig
	self.Tracks = {}
	self.PreviousTrack = nil

	--// loading animations
	local Animator = Rig:WaitForChild("Humanoid"):WaitForChild("Animator")

	local Animations
	if getDescendants then
		Animations = AnimationsFolder:GetDescendants()
	else
		Animations = AnimationsFolder:GetChildren()
	end

	for _, animationInstance in Animations do
		self.Tracks[animationInstance.Name] = Animator:LoadAnimation(animationInstance)
	end

	return self
end

function AnimationHandler:Play(trackName)
	local track = self.Tracks[trackName]
	if not track then
		warn("[AnimationHandler] Animation '" .. tostring(trackName) .. "' not found.")
		return
	end
	if self.PreviousTrack then
		self.PreviousTrack:Stop()
	end
	track:Play()
	self.PreviousTrack = track
end

function AnimationHandler:IsPlaying(trackName)
	local track = self.Tracks[trackName]
	if not track then
		warn("[AnimationHandler] Animation '" .. tostring(trackName) .. "' not found.")
		return false
	end
	return track.IsPlaying
end

function AnimationHandler:StopAll()
	for _, track in self.Tracks do
		track:Stop()
	end
end

return AnimationHandler
