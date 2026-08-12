--[CONFIG]--
local detectZone = game.Workspace:WaitForChild("UnLoadZone")
local CollectionService = game:GetService("CollectionService")
local UnLoad_event = game.ReplicatedStorage.UnLoad_Event

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

--[ GET DRIVER ]--
local function getOccupantPlayer()
	local occupant = Seat and Seat.Occupant
	return occupant and occupant.Parent and Players:GetPlayerFromCharacter(occupant.Parent)
end

connect.Event:Connect(function(data)
	local wagon = data.Parent

	if wagon and not table.find(wagons, wagon) then
		table.insert(wagons, wagon)
	end
end)

local function getNextLoadedWagon()
	local partsInZone = workspace:GetPartsInPart(detectZone)
	local zoneType = detectZone:GetAttribute("UnLoadType")

	for _, wagon in ipairs(wagons) do
		local base = wagon:FindFirstChild("Base")
		local wagonType = wagon:GetAttribute("WagonType")

		if base and table.find(partsInZone, base) and wagonType == zoneType then
			local currentLoad = wagon:GetAttribute("CurrentLoad")
			local maxLoad = wagon:GetAttribute("MaxCapacity")

			if currentLoad > 0 then
				return wagon
			end
		end
	end

	return nil
end

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
			
			--[ECONOMY]--
			local player = getOccupantPlayer()
			local leaderstats = player:FindFirstChild("leaderstats")
			local cashStat = leaderstats and leaderstats:FindFirstChild("Cash")

			if cashStat then 
				cashStat.Value += 10
				print("Cash Added")
			end

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
			local player = getOccupantPlayer()

			if player and getNextLoadedWagon() then
				UnLoad_event:FireClient(player, true)
			end

			break
		end
	end
end)


UnLoad_event.OnServerEvent:Connect(function(player)
	if isLoadingProcess then 
		return 
	end

	isLoadingProcess = true

	UnLoad_event:FireClient(player, false)

	while true do
		local targetWagon = getNextLoadedWagon()

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

	local remaining = getNextLoadedWagon()

	if remaining and getOccupantPlayer() == player then
		UnLoad_event:FireClient(player, true)
	else
		UnLoad_event:FireClient(player, false)
	end
end)
