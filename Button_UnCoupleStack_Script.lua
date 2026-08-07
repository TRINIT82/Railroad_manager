local button = script.Parent
button.Active = false
button.Visible = false

game.ReplicatedStorage.UnCoupleStack.OnClientEvent:Connect(function(isActive)
	button.Active = isActive
	button.Visible = isActive
end)

script.Parent.Activated:Connect(function()
	if button then
		game.ReplicatedStorage.UnCoupleStack:FireServer()
	end
end)
