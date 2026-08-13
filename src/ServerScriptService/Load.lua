--[CONFIG]--
local detectZone = game.Workspace:WaitForChild("LoadZone")
local CollectionService = game:GetService("CollectionService")
local Load_event = game.ReplicatedStorage.Load_Event
local PlayerUtils = require(game.ReplicatedStorage.Modules:WaitForChild("PlayerUtils"))
local WagonUtils = require(game.ReplicatedStorage.Modules:WaitForChild("WagonUtils"))

local buttonState = {}

--[ITEM]--
local item = game.ServerStorage:WaitForChild("planks")
local spawn_area = game.Workspace:WaitForChild("WoodSpawn")

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
		print("New wagon registered:", wagon.Name)
	end
end)



Players.PlayerRemoving:Connect(function(player)
	buttonState[player] = nil
end)

local function spawnWood()
	
	task.wait(1)
	
	local wood = item:Clone()
	
	wood.Parent = game.Workspace
	wood.CFrame = spawn_area.CFrame * CFrame.new(0, 3, 0)
	wood.CFrame = wood.CFrame * CFrame.Angles(0, math.rad(90), 0)
	
	CollectionService:AddTag(wood, "WoodOnPlatform")
	print("New wood spawned on platform 1")
end

local function load(wagon)
	local currentLoad = wagon:GetAttribute("CurrentLoad")
	local maxLoad = wagon:GetAttribute("MaxCapacity")

	if currentLoad >= maxLoad then 
		return false 
	end

	local oldWood = CollectionService:GetTagged("WoodOnPlatform")[1]
	local AnimEnd = wagon:FindFirstChild("AnimEnd")
	
	local Visual1 = wagon:FindFirstChild("VisualW1")
	local Visual2 = wagon:FindFirstChild("VisualW2")

	if not oldWood or not AnimEnd or not Visual1 or not Visual2 then
		print("No wood")
		return false
	end

	local newLoad = currentLoad + 1
	wagon:SetAttribute("CurrentLoad", newLoad)

	oldWood:Destroy()
	task.wait(0.3)

	local newItem = item:Clone()
	
	newItem.Parent = game.Workspace
	newItem.CFrame = AnimEnd.CFrame * CFrame.new(0, 10, 0)
	newItem.CFrame = newItem.CFrame * CFrame.Angles(0, math.rad(90), 0)
	CollectionService:AddTag(newItem, "WoodInTransit")

	local isLoaded = false
	local connection
	
	connection = AnimEnd.Touched:Connect(function(hit)
		if hit == newItem or hit:IsDescendantOf(newItem) then
			if connection then 
				connection:Disconnect() 
			end
			
			newItem:Destroy()
			
			Visual1.Transparency = 0
			Visual2.Transparency = 0
			
			print("Loaded to", wagon.Name, "| Progress:", newLoad, "/", maxLoad)
			isLoaded = true
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

	spawnWood()
	
	return true
end

detectZone.Touched:Connect(function(hit)
	if isLoadingProcess then 
		return 
	end

	local wagonType = hit.Parent:GetAttribute("WagonType")
	local zoneType = detectZone:GetAttribute("LoadType")

	for _, wagon in ipairs(wagons) do
		if hit == wagon.Base and wagonType == zoneType then
			local player = PlayerUtils.getOccupantPlayer(Seat)
			
			if player and WagonUtils.getNextEmptyWagon(detectZone, wagons) then
				PlayerUtils.setButtonState(Load_event,buttonState,player, true)
			end
			
			break
		end
	end
end)

detectZone.TouchEnded:Connect(function(hit)
	local wagonType = hit.Parent and hit.Parent:GetAttribute("WagonType")
	local zoneType = detectZone:GetAttribute("LoadType")

	if wagonType ~= zoneType then 
		return 
	end

	local player = PlayerUtils.getOccupantPlayer(Seat)
	if player then
		PlayerUtils.setButtonState(Load_event,buttonState,player, false)
	end
end)


Load_event.OnServerEvent:Connect(function(player)
	if isLoadingProcess then 
		return 
	end
	
	isLoadingProcess = true

	PlayerUtils.setButtonState(Load_event,buttonState,player, false)

	while true do
		local targetWagon = WagonUtils.getNextEmptyWagon(detectZone, wagons)

		if not targetWagon then
			print("All wagons are full")
			break
		end

		local success = load(targetWagon)
		
		if not success then
			break
		end

		task.wait(1)
	end

	isLoadingProcess = false

	local remaining = WagonUtils.getNextEmptyWagon(detectZone, wagons)
	
	if remaining and PlayerUtils.getOccupantPlayer(Seat) == player then
		PlayerUtils.setButtonState(Load_event,buttonState,player, true)
	else
		PlayerUtils.setButtonState(Load_event,buttonState,player, false)
	end
end)

spawnWood()
