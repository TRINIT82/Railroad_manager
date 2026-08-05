local Keybinds = game:GetService("ReplicatedStorage").Events.Keybinds
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")


local KeyMappings = {
	[Enum.KeyCode.R] = "R",
	[Enum.KeyCode.H] = "H",
}

UIS.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end
	
	local KeyCode = input.KeyCode
	local mapping = KeyMappings[KeyCode]
	if mapping then
		Keybinds:FireServer(mapping)
	end
end)

RunService.RenderStepped:Connect(function()
	local Train = script:FindFirstChild("Train")
	local TRAINGui = script:FindFirstChild("TRAINGui")
	if not Train or not Train.Value or not TRAINGui then return end

	local Base = Train.Value.Chassis:FindFirstChild("Base")
	if not Base then return end

	local LinearVelocity = Base:FindFirstChild("LinearVelocity")
	if not LinearVelocity then return end

	local background = TRAINGui:FindFirstChild("BACKGROUND")
	if not background then return end

	local speedIndicator = background:FindFirstChild("SPEEDINDICATOR")
	local directionLabel = background:FindFirstChild("DIRECTION")

	if speedIndicator then
		speedIndicator.Text = tostring(math.floor(LinearVelocity.LineVelocity))
	end

	if directionLabel then
		if Train.Value.Chassis.Data.Direction.Value == 1 then
			directionLabel.Text = "Direction: Forward"
		elseif Train.Value.Chassis.Data.Direction.Value == 0 then
			directionLabel.Text = "Direction: Reverse"
		end
	end
end)
