--[CONFIG]--
local detectZone = game.Workspace:WaitForChild("LoadZone")
local CollectionService = game:GetService("CollectionService")
local Load_event = game.ReplicatedStorage.Load_Event

--[ITEM]--
local item = game.ServerStorage:WaitForChild("wood_part")
local spawn_area = game.Workspace:WaitForChild("WoodSpawn")

--[TRAIN]--
local Chassis = workspace:FindFirstChild("Chassis")
local connect = game.ServerStorage:WaitForChild("Connections")

local wagons = {}

--[Player]--
local Seat = Chassis and Chassis:FindFirstChild("DriverSeat")
local Players = game:GetService("Players")
local isLoadingProcess = false

--[ GET DRIVER ]--
local function getOccupantPlayer()
	local occupant = Seat and Seat.Occupant
	return occupant and occupant.Parent and Players:GetPlayerFromCharacter(occupant.Parent)
end

connect.Event:Connect(function(data)
	local wagon = data.Parent

	if wagon and not table.find(wagons, wagon) then
		table.insert(wagons, wagon)
		print("New wagon registered:", wagon.Name)
	end
end)

local function getNextEmptyWagon()
	local partsInZone = workspace:GetPartsInPart(detectZone)

	for _, wagon in ipairs(wagons) do
		local base = wagon:FindFirstChild("Base")

		if base and table.find(partsInZone, base) then
			local currentLoad = wagon:GetAttribute("CurrentLoad")
			local maxLoad = wagon:GetAttribute("MaxCapacity")

			if currentLoad < maxLoad then
				return wagon
			end
		end
	end
	
	return nil
end

local function spawnWood()
	
	task.wait(2)
	
	local wood = item:Clone()
	wood.Parent = game.Workspace
	wood.CFrame = spawn_area.CFrame * CFrame.new(0, 3, 0)
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
	local Visual = wagon:FindFirstChild("VisualW")

	if not oldWood or not AnimEnd or not Visual then
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
	CollectionService:AddTag(newItem, "WoodInTransit")

	local isLoaded = false
	local connection
	
	connection = AnimEnd.Touched:Connect(function(hit)
		if hit == newItem or hit:IsDescendantOf(newItem) then
			if connection then 
				connection:Disconnect() 
			end
			
			newItem:Destroy()
			Visual.Transparency = 0
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
			local player = getOccupantPlayer()
			
			if player and getNextEmptyWagon() then
				Load_event:FireClient(player, true)
			end
			
			break
		end
	end
end)


Load_event.OnServerEvent:Connect(function(player)
	if isLoadingProcess then return end
	isLoadingProcess = true

	Load_event:FireClient(player, false)

	while true do
		local targetWagon = getNextEmptyWagon()

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

	local remaining = getNextEmptyWagon()
	if remaining and getOccupantPlayer() == player then
		Load_event:FireClient(player, true)
	else
		Load_event:FireClient(player, false)
	end
end)

spawnWood()
