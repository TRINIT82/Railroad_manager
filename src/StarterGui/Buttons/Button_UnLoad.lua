local button = script.Parent

button.Active = false
button.Visible = false

game.ReplicatedStorage.UnLoad_Event.OnClientEvent:Connect(function(isActive)
	print("Button is Active")
	button.Active = isActive
	button.Visible = isActive
end)

button.Activated:Connect(function()
	if button then 
		print("FireServer")
		game.ReplicatedStorage.UnLoad_Event:FireServer()
	end
end)
