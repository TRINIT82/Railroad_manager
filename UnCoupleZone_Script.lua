local button = script.Parent
button.Active = false
button.Visible = false
local currentCoupler = nil

game.ReplicatedStorage.UnCoupleZone.OnClientEvent:Connect(function(isActive, coupler)
	print("Button is Active")
	button.Active = isActive
	button.Visible = isActive
	currentCoupler = coupler
end)

script.Parent.Activated:Connect(function()
	if button and currentCoupler then
		print("FireServer", currentCoupler:GetFullName())
		game.ReplicatedStorage.UnCoupleZone:FireServer(currentCoupler)
	end
end)
