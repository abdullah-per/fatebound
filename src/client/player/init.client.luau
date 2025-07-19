--// Disable health bar
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

--// Enable character archiving
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character.Archivable = true
	end)
end)
