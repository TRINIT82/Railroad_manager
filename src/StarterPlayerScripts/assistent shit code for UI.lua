local Keybinds = game:GetService("ReplicatedStorage").Events.Keybinds
local TrainControl = game:GetService("ReplicatedStorage").Events.TrainControl
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local MAX_SPEED = 50

local throttleValue = 0
local brakeValue = 0
local draggingThrottle = false
local draggingBrake = false

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

-- ===== SLIDER SETUP =====
local function setupSlider(track, handle, fill, isDraggingVar, onValueChanged)
	if not track or not handle then return end
	
	local function updateSlider(inputPos)
		local trackPos = track.AbsolutePosition
		local trackSize = track.AbsoluteSize
		-- Vertical slider: 0 at bottom, 1 at top
		local relativeY = inputPos.Y - trackPos.Y
		local pct = 1 - math.clamp(relativeY / trackSize.Y, 0, 1)
		onValueChanged(pct)
		
		-- Update visual
		local fillHeight = pct * trackSize.Y
		if fill then
			fill.Size = UDim2.new(1, 0, 0, fillHeight)
		end
		handle.Position = UDim2.new(0, -2, 1, -fillHeight - 8)
	end
	
	-- Start dragging when clicking handle
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if isDraggingVar == "throttle" then
				draggingThrottle = true
			else
				draggingBrake = true
			end
		end
	end)
	
	-- Start dragging and jump to click position when clicking track
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if isDraggingVar == "throttle" then
				draggingThrottle = true
			else
				draggingBrake = true
			end
			updateSlider(input.Position)
		end
	end)
	
	-- Handle drag movement
	UIS.InputChanged:Connect(function(input)
		local isDragging = (isDraggingVar == "throttle") and draggingThrottle or draggingBrake
		if not isDragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateSlider(input.Position)
		end
	end)
end

-- ===== INITIALIZE SLIDERS =====
local slidersInitialized = false

local function initSliders(gui)
	if slidersInitialized then return end
	local mainPanel = gui:FindFirstChild("MainPanel")
	if not mainPanel then return end
	
	local throttleGroup = mainPanel:FindFirstChild("ThrottleGroup")
	if throttleGroup then
		local track = throttleGroup:FindFirstChild("Track")
		local handle = track and track:FindFirstChild("Handle")
		local fill = track and track:FindFirstChild("Fill")
		setupSlider(track, handle, fill, "throttle", function(v)
			throttleValue = v
			TrainControl:FireServer("Throttle", v)
		end)
	end
	
	local brakeGroup = mainPanel:FindFirstChild("BrakeGroup")
	if brakeGroup then
		local track = brakeGroup:FindFirstChild("Track")
		local handle = track and track:FindFirstChild("Handle")
		local fill = track and track:FindFirstChild("Fill")
		setupSlider(track, handle, fill, "brake", function(v)
			brakeValue = v
			TrainControl:FireServer("Brake", v)
		end)
	end
	
	-- Stop dragging on mouse release
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingThrottle = false
			draggingBrake = false
		end
	end)
	
	slidersInitialized = true
end

RunService.RenderStepped:Connect(function()
	local Train = script:FindFirstChild("Train")
	local TRAINGui = script:FindFirstChild("TRAINGui")
	if not Train or not Train.Value or not TRAINGui then return end

	local chassis = Train.Value:FindFirstChild("Chassis")
	if not chassis then return end

	local Base = chassis:FindFirstChild("Base")
	if not Base then return end

	local LinearVelocity = Base:FindFirstChild("LinearVelocity")
	if not LinearVelocity then return end

	local Data = chassis:FindFirstChild("Data")
	if not Data then return end

	local mainPanel = TRAINGui:FindFirstChild("MainPanel")
	if not mainPanel then return end

	-- Initialize sliders on first valid frame
	initSliders(TRAINGui)

	-- ===== SPEEDOMETER =====
	local speedo = mainPanel:FindFirstChild("Speedometer")
	if speedo then
		local speedVal = speedo:FindFirstChild("SpeedValue")
		local speedBarBg = speedo:FindFirstChild("SpeedBarBg")
		local speedBarFill = speedBarBg and speedBarBg:FindFirstChild("SpeedBarFill")
		
		local currentSpeed = math.abs(LinearVelocity.LineVelocity)
		local speedLimitVal = Data:FindFirstChild("SpeedLimit")
		local limit = (speedLimitVal and speedLimitVal.Value) or MAX_SPEED
		
		if speedVal then
			speedVal.Text = tostring(math.floor(currentSpeed))
			if currentSpeed > limit then
				speedVal.TextColor3 = Color3.fromRGB(255, 80, 80)
			else
				speedVal.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
		
		if speedBarFill then
			local pct = math.clamp(currentSpeed / MAX_SPEED, 0, 1)
			speedBarFill.Size = UDim2.new(pct, 0, 1, 0)
			if pct < 0.6 then
				speedBarFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			elseif pct < 0.85 then
				speedBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
			else
				speedBarFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			end
		end
		
		-- Speed warning
		local warning = speedo:FindFirstChild("SpeedWarning")
		if warning then
			local warnText = warning:FindFirstChild("WarningText")
			if warnText then
				if currentSpeed > limit then
					warnText.Text = "⚠ ПРЕВЫШЕНИЕ!"
				else
					warnText.Text = ""
				end
			end
		end
	end

	-- ===== THROTTLE DISPLAY =====
	local throttleGroup = mainPanel:FindFirstChild("ThrottleGroup")
	if throttleGroup then
		local pctLabel = throttleGroup:FindFirstChild("Percent")
		if pctLabel then
			pctLabel.Text = tostring(math.floor(throttleValue * 100)) .. "%"
		end
		-- Sync visual when not dragging
		local track = throttleGroup:FindFirstChild("Track")
		if track and not draggingThrottle then
			local fill = track:FindFirstChild("Fill")
			local handle = track:FindFirstChild("Handle")
			local fillHeight = throttleValue * track.AbsoluteSize.Y
			if fill then
				fill.Size = UDim2.new(1, 0, 0, fillHeight)
			end
			if handle then
				handle.Position = UDim2.new(0, -2, 1, -fillHeight - 8)
			end
		end
	end

	-- ===== BRAKE DISPLAY =====
	local brakeGroup = mainPanel:FindFirstChild("BrakeGroup")
	if brakeGroup then
		local pctLabel = brakeGroup:FindFirstChild("Percent")
		if pctLabel then
			pctLabel.Text = tostring(math.floor(brakeValue * 100)) .. "%"
		end
		local track = brakeGroup:FindFirstChild("Track")
		if track and not draggingBrake then
			local fill = track:FindFirstChild("Fill")
			local handle = track:FindFirstChild("Handle")
			local fillHeight = brakeValue * track.AbsoluteSize.Y
			if fill then
				fill.Size = UDim2.new(1, 0, 0, fillHeight)
			end
			if handle then
				handle.Position = UDim2.new(0, -2, 1, -fillHeight - 8)
			end
		end
	end

	-- ===== DIRECTION INDICATOR =====
	local dirGroup = mainPanel:FindFirstChild("DirectionGroup")
	if dirGroup then
		local dirIcon = dirGroup:FindFirstChild("DirIcon")
		local dirText = dirGroup:FindFirstChild("DirText")
		if dirIcon and dirText then
			if Data.Direction.Value == 1 then
				dirIcon.Text = "▶"
				dirIcon.TextColor3 = Color3.fromRGB(0, 200, 100)
				dirText.Text = "ВПЕРЁД"
				dirText.TextColor3 = Color3.fromRGB(0, 200, 100)
			else
				dirIcon.Text = "◀"
				dirIcon.TextColor3 = Color3.fromRGB(255, 170, 50)
				dirText.Text = "НАЗАД"
				dirText.TextColor3 = Color3.fromRGB(255, 170, 50)
			end
		end
	end

	-- ===== SPEED LIMIT SIGN =====
	local limitSign = mainPanel:FindFirstChild("SpeedLimit")
	if limitSign then
		local limitValueLabel = limitSign:FindFirstChild("LimitValue")
		local speedLimitVal = Data:FindFirstChild("SpeedLimit")
		if limitValueLabel and speedLimitVal then
			limitValueLabel.Text = tostring(speedLimitVal.Value)
		end
	end
end)
