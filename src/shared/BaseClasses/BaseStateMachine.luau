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
	self.BeforePreviousState = nil

	self.Enabled = false
	self.Connections = {}
	return self
end

function BaseMachine:ChangeState(newState)
	self.BeforePreviousState = self.PreviousState
	self.PreviousState = self.CurrentState
	self.CurrentState = newState

	if self.PreviousState and self.PreviousState.Exit then
		self.PreviousState:Exit()
	end

	self.CurrentState:Enter(self)
end

function BaseMachine:DelegateInput(input: InputObject, eventType: string)
	if self.Enabled then
		self.CurrentState:HandleInput(self, input, eventType)
	end
end

function BaseMachine:DelegateUpdate(deltaTime)
	-- print(self.Current_Stamina)

	if self.Enabled then
		self.CurrentState:Update(self, deltaTime)
	end
end

function BaseMachine:Enable(state)
	print("[StateMachine] Enabling:", self.Name)
	self.CurrentState = state or self.DefaultState
	self.Enabled = true

	local inputBegan = UserInputService.InputBegan:Connect(function(input, _gameProc)
		if not _gameProc then
			self:DelegateInput(input, "began")
		end
	end)

	local inputEnded = UserInputService.InputEnded:Connect(function(input, _gameProc)
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

	if self.CurrentState and self.CurrentState.Enter then
		self.CurrentState:Enter(self)
	end
end

function BaseMachine:Disable()
	print("[StateMachine] Disabling:", self.Name)
	for _, connection in self.Connections do
		connection:Disconnect()
	end

	self.Enabled = false
end

return BaseMachine
