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

--[ GET DRIVER ]--
local function getOccupantPlayer()
	local occupant = Seat and Seat.Occupant
	return occupant and occupant.Parent and Players:GetPlayerFromCharacter(occupant.Parent)
end

connect.Event:Connect(function(data)
	local wagon = data.Parent
	table.insert(wagons, wagon)
	print("New wagon registered:", wagon:GetFullName())
	
end)

local function spawnWood()
	
	task.wait(5)
	
	local wood = item:Clone()
	wood.Parent = game.Workspace
	wood.CFrame = spawn_area.CFrame * CFrame.new(0, 3, 0)
	CollectionService:AddTag(wood, "WoodOnPlatform")
	print("New wood spawned on platform 1")
end

local function Load(wagon)
	
	local oldWood = CollectionService:GetTagged("WoodOnPlatform")[1]
	local AnimEnd = wagon:WaitForChild("AnimEnd")
	local Visual = wagon:WaitForChild("VisualW")

	if not oldWood then
		print("No wood on platform 1 to teleport")
		return
	end

	oldWood:Destroy()

	task.wait(0.5)
	
	local newItem = item:Clone()
	newItem.Parent = game.Workspace
	newItem.CFrame = AnimEnd.CFrame * CFrame.new(0, 10, 0)-- This sets the position to where the item will drop
	CollectionService:AddTag(newItem, "WoodInTransit")
	
	AnimEnd.Touched:Connect(function(hit)
		newItem:Destroy()
		Visual.Transparency = 0
		print("Wood has been loaded to Wagon")
	end)
	
end

detectZone.Touched:Connect(function(hit)
	
	local wagonType = hit.Parent:GetAttribute("WagonType")
	local zoneType = detectZone:GetAttribute("LoadType")
	
	for _, wagon in ipairs(wagons) do
		if hit == wagon.Base and wagonType == zoneType then
			print("Detected correct wagon:", wagon:GetFullName())

			local player = getOccupantPlayer()
			
			if player then
				Load_event:FireClient(player, true)
			end

			break
		end
	end
end)

Load_event.OnServerEvent:Connect(function(player)
	Load(wagons[1])
	task.wait(3)
	Load_event:FireClient(player, false)
end)

spawnWood()
