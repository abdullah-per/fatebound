game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character.Archivable = true
	end)
end)
