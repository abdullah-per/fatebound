local SoundHandler = {}
SoundHandler.__index = SoundHandler

function SoundHandler.new(SoundsFolder, getDescendants)
	local self = setmetatable({}, SoundHandler)

	self.Tracks = {}
	self.PreviousTrack = nil

	--// adding sounds

	local Sounds
	if getDescendants then
		Sounds = SoundsFolder:GetDescendants()
	else
		Sounds = SoundsFolder:GetChildren()
	end

	for _, soundInstance in Sounds do
		self.Tracks[soundInstance.Name] = soundInstance
	end

	return self
end

function SoundHandler:Play(trackName)
	if self.PreviousTrack then
		self.PreviousTrack:Stop()
	end

	self.Tracks[trackName]:Play()
	self.PreviousTrack = self.Tracks[trackName]
end

return SoundHandler
