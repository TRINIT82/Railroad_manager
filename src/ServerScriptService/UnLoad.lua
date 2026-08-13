--[CONFIG]--
local detectZone = game.Workspace:WaitForChild("UnLoadZone")
local CollectionService = game:GetService("CollectionService")
local UnLoad_event = game.ReplicatedStorage.UnLoad_Event
local PlayerUtils = require(game.ReplicatedStorage.Modules:WaitForChild("PlayerUtils"))
local WagonUtils = require(game.ReplicatedStorage.Modules:WaitForChild("WagonUtils"))

local buttonState = {}

--[ITEM]--
local item = game.ServerStorage:WaitForChild("planks")
local spawn_area = game.Workspace:WaitForChild("WoodStorage")
local visual_wood = game.Workspace.WoodStorage:WaitForChild("Visual_wood")

--[TRAIN]--
local Chassis = workspace:FindFirstChild("Chassis")
local connect = game.ServerStorage:WaitForChild("Connections")

local wagons = {}

--[Player]--
local Seat = Chassis and Chassis:FindFirstChild("DriverSeat")
local Players = game:GetService("Players")
local isLoadingProcess = false

connect.Event:Connect(function(data)
	local wagon = data.Parent

	if wagon and not table.find(wagons, wagon) then
		table.insert(wagons, wagon)
	end
end)

local function spawnWood()

	task.wait(0.5)
--[PHYSIC]--

	--local wood = item:Clone()
	--wood.Parent = game.Workspace
	--wood:PivotTo(spawn_area.CFrame * CFrame.new(0, 3, 0))
	--CollectionService:AddTag(wood, "WoodOnPlatform")
	
	visual_wood.Transparency = 0
	
	print("New wood spawned on Storage Platform")
	
end

local OnPlatform = false

local function Unload(wagon)
	
	local currentLoad = wagon:GetAttribute("CurrentLoad")
	local maxLoad = wagon:GetAttribute("MaxCapacity")

	if currentLoad <= 0 then 
		return false 
	end

	-- local oldWood = CollectionService:GetTagged("WoodOnPlatform")[1]
	local AnimEnd = game.Workspace:WaitForChild("Wood_Unload")
	
	local Visual1 = wagon:FindFirstChild("VisualW1")
	local Visual2 = wagon:FindFirstChild("VisualW2")

	if not AnimEnd or not Visual1 or not Visual2 then
		print("AnimEnd or Visual not found")
		return false
	end

	local newLoad = currentLoad - 1
	
	wagon:SetAttribute("CurrentLoad", newLoad)

	--oldWood:Destroy()
	Visual1.Transparency = 1
	Visual2.Transparency = 1
	
	print("UnLoaded From", wagon.Name, "| Progress:", newLoad, "/", maxLoad)
	
	task.wait(0.3)

	local newItem = item:Clone()

	newItem.Parent = game.Workspace
	newItem:PivotTo(AnimEnd.CFrame * CFrame.new(0, 10, 0))
	newItem.CFrame = newItem.CFrame * CFrame.Angles(0, math.rad(90), 0)
	
	CollectionService:AddTag(newItem, "WoodInTransit")
	
	local isLoaded = false
	local connection

	connection = AnimEnd.Touched:Connect(function(hit)
		if hit == newItem or hit:IsDescendantOf(newItem) then
			
			newItem:Destroy()
			
			if connection then 
				connection:Disconnect() 
			end
			
			isLoaded = true
			
			if not OnPlatform then
				OnPlatform = true
				spawnWood()
			end
			
		end
	end)

	local timer = 0
	while not isLoaded and timer < 3 do
		task.wait(0.1)
		timer += 0.1
	end
	
	if connection and connection.Connected then 
		connection:Disconnect() 
	end

	return true
end

detectZone.Touched:Connect(function(hit)
	if isLoadingProcess then
		return 
	end

	local wagonType = hit.Parent:GetAttribute("WagonType")
	local zoneType = detectZone:GetAttribute("UnLoadType")

	for _, wagon in ipairs(wagons) do
		if hit == wagon.Base and wagonType == zoneType then
			local player = PlayerUtils.getOccupantPlayer(Seat)

			if player and WagonUtils.getNextLoadedWagon(detectZone, wagons) then
				PlayerUtils.setButtonState(UnLoad_event,buttonState,player, true)
			end

			break
		end
	end
end)

detectZone.TouchEnded:Connect(function(hit)
	local wagonType = hit.Parent and hit.Parent:GetAttribute("WagonType")
	local zoneType = detectZone:GetAttribute("UnLoadType")

	if wagonType ~= zoneType then 
		return 
	end

	local player = PlayerUtils.getOccupantPlayer(Seat)
	if player then
		PlayerUtils.setButtonState(UnLoad_event,buttonState,player, false)
	end
end)

UnLoad_event.OnServerEvent:Connect(function(player)
	if isLoadingProcess then 
		return 
	end

	isLoadingProcess = true

	PlayerUtils.setButtonState(UnLoad_event,buttonState,player, false)

	while true do
		local targetWagon = WagonUtils.getNextLoadedWagon(detectZone, wagons)
		if not targetWagon then
			print("All wagons are Empty")
			break
		end

		local success = Unload(targetWagon)
		if not success then
			break
		end

		task.wait(1)
	end

	isLoadingProcess = false

	local remaining = WagonUtils.getNextLoadedWagon(detectZone, wagons)

	if remaining and PlayerUtils.getOccupantPlayer(Seat) == player then
		PlayerUtils.setButtonState(UnLoad_event,buttonState,player, true)
	else
		PlayerUtils.setButtonState(UnLoad_event,buttonState,player, false)
	end
end)
