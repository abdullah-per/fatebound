--// Services
local UserInputService = game:GetService("UserInputService")

--// Input Handler
local InputHandler = {}

InputHandler.AllPressed = function(...: Enum.KeyCode)
	local inputs = { ... }
	for _, input in inputs do
		if not UserInputService:IsKeyDown(input) then
			return false
		end
	end
	return true
end

InputHandler.AnyPressed = function(...: Enum.KeyCode)
	local inputs = { ... }
	for _, input in inputs do
		if UserInputService:IsKeyDown(input) then
			return true
		end
	end
	return false
end

return InputHandler
