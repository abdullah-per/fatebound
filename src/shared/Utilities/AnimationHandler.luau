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
	if self.PreviousTrack then
		self.PreviousTrack:Stop()
	end

	self.Tracks[trackName]:Play()
	self.PreviousTrack = self.Tracks[trackName]
end

return AnimationHandler
