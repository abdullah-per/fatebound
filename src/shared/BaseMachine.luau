--[[
    - Base machine class.
]]

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Base Machine
local BaseMachine = {}
BaseMachine.__index = BaseMachine

function BaseMachine.new(machineName: string)
	local self = setmetatable({}, BaseMachine)
	self.Name = machineName or "DefaultMachine"

	self.States = {}

	self.DefaultState = nil
	self.CurrentState = nil
	self.PreviousState = nil

	self.Enabled = false
	self.Connections = {}
	return self
end

function BaseMachine:ChangeState(newState)
	self.PreviousState = self.CurrentState
	self.CurrentState = newState

	self.PreviousState:Exit()
	self.CurrentState:Enter()
end

function BaseMachine:DelegateInput(input: InputObject, eventType: string)
	if self.Enabled then
		self.CurrentState:HandleInput(input, eventType)
	end
end

function BaseMachine:DelegateUpdate(deltaTime)
	if self.Enabled then
		self.CurrentState:Update(deltaTime)
	end
end

function BaseMachine:Enter()
	local inputBegan = UserInputService.InputBegan:Connect(function(input, _gameProc)
		if not _gameProc then
			self:DelegateInput(input, "began")
		end
	end)

	local inputEnded = UserInputService.InputBegan:Connect(function(input, _gameProc)
		if not _gameProc then
			self:DelegateInput(input, "ended")
		end
	end)

	local update = RunService.Heartbeat:Connect(function(deltaTime)
		self:DelegateUpdate(deltaTime)
	end)

	table.insert(self.Connections, inputBegan)
	table.insert(self.Connections, inputEnded)
	table.insert(self.Connections, update)
end

function BaseMachine:Exit()
	for _, connection in self.Connections do
		connection:Disconnect()
	end
end

return BaseMachine
