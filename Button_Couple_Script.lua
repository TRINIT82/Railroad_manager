local button = script.Parent

button.Active = false
button.Visible = false

game.ReplicatedStorage.Couple.OnClientEvent:Connect(function(isActive)
	print("Button is Active")
	button.Active = isActive
	button.Visible = isActive
end)

script.Parent.Activated:Connect(function()
	if button then
		print("FireServer")
		game.ReplicatedStorage.Couple:FireServer()
	end
end)
