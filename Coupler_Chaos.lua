local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Chassis = Workspace:FindFirstChild("Chassis")
local Seat = Chassis and Chassis:FindFirstChild("DriverSeat")

local Couple = ReplicatedStorage:WaitForChild("Couple")

local UnCoupleStack = game.ReplicatedStorage:WaitForChild("UnCoupleStack")
local UnCoupleZone = game.ReplicatedStorage:WaitForChild("UnCoupleZone")

local connections = {}
local pendingCouple = nil
local prevDriver = nil

local connect = game.ServerStorage:WaitForChild("Connections")

--[ GET DRIVER ]--
local function getOccupantPlayer()
	local occupant = Seat and Seat.Occupant
	return occupant and occupant.Parent and Players:GetPlayerFromCharacter(occupant.Parent)
end

--[ COUPLER CHECKER ]--
local function isCoupler(part)
	return part:IsA("BasePart") and part.Name:lower():find("coupler") ~= nil
end

--[CONNECTION CHECKER]--
local function findConnection(coupler)
	for i, conn in ipairs(connections) do
		if conn.couplerA == coupler or conn.couplerB == coupler then return i, conn end
	end
end

--[GET WAGON TYPE]--
--local function getWagonType(coupler)
--	-- coupler.Parent — це модель вагона (як у твоєму isPartOfTrain)
--	local wagon = coupler.Parent
--	return wagon and wagon:GetAttribute("WagonType")
--end

----[GET TRAIN TYPE]--
--local function getTrainType()
--	-- якщо є хоч одне з'єднання - беремо тип першого вагона в ньому
--	if #connections > 0 then
--		return getWagonType(connections[1].couplerA)
--	end
--	return nil -- потяг ще порожній, тип ще не зафіксований
--end

--[PART OF THE TRAIN ?]--
local function isPartOfTrain(coupler)
	if Chassis and coupler.Parent == Chassis then 
		return true 
	end
	
	for _, conn in ipairs(connections) do
		if conn.couplerA.Parent == coupler.Parent or conn.couplerB.Parent == coupler.Parent then
			return true
		end
	end
	
	return false
	
end

--[CREATE/FIND ATTACHMENTS]--
local function getAttachment(part)
	local attach = part:FindFirstChild("CouplerAttachment")
	
	if not attach then
		attach = Instance.new("Attachment")
		attach.Name = "CouplerAttachment"
		attach.Parent = part
	end
	
	return attach
	
end

--[CHECK VALID DISTANCE FOR COUPLER]--
local function isValidPair(cA, cB, maxDist)
	if not (cA and cB and cA.Parent and cB.Parent) then 
		return false 
	end
	
	if maxDist and (cA.Position - cB.Position).Magnitude > maxDist then 
		return false 
	end
	
	return isPartOfTrain(cA) or isPartOfTrain(cB)
	
	--if not (isPartOfTrain(cA) or isPartOfTrain(cB)) then 
	--	return false 
	--end
	
	--local trainType = getTrainType()
	--if trainType then
	--	local newWagonType = getWagonType(isPartOfTrain(cA) and cB or cA)
	--	if newWagonType ~= trainType then
	--		return false
	--	end
	--end
	
	--return true
	
end

--[ZONE DETECTION - FOR UNCOUPLE BUTTON]--]--
local function setupUncoupleZone(coupler, connectionData)
	-- Touched/зона навколо coupler'а, показує кнопку коли гравець поруч

	local zone = coupler:FindFirstChild("UncoupleZone") -- частина-тригер біля кюплера
	if not zone then 
		return 
	end
	
	local partsInZone = {}

	zone.Touched:Connect(function(hit)

		local character = hit.Parent
		local player = game.Players:GetPlayerFromCharacter(character)
		
		if player then
			partsInZone[player] = (partsInZone[player] or 0) + 1
			if partsInZone[player] == 1 and findConnection(coupler) then
				UnCoupleZone:FireClient(player, true, coupler)
			end
		end
	end)

	zone.TouchEnded:Connect(function(hit)
		local character = hit.Parent
		local player = game.Players:GetPlayerFromCharacter(character)
		
		if player and partsInZone[player] then
			partsInZone[player] = partsInZone[player] - 1
			if partsInZone[player] <= 0 then
				partsInZone[player] = nil
				UnCoupleZone:FireClient(player, false, coupler)
			end
		end
	end)
end

--[CREATE CONNECTION]--
local function connectCouplers(cA, cB)
	
	local newCoupler = cB
	if isPartOfTrain(cB) then
		newCoupler = cA
	end
	
	local rod = Instance.new("RodConstraint")
	
	rod.Name = "CouplerWeld_" .. (#connections + 1)
	rod.Attachment0, rod.Attachment1 = getAttachment(cA), getAttachment(cB)
	rod.Length, rod.Thickness, rod.Visible = 5, 0.5, true
	rod.Parent = cA

	local connectionData = { couplerA = cA, couplerB = cB, rod = rod }
	table.insert(connections, connectionData)
	
	connect:Fire(newCoupler)
	print("Connection Fired for NEW wagon:", newCoupler.Parent.Name)
	
	setupUncoupleZone(cA, connectionData)
	setupUncoupleZone(cB, connectionData)
	
	print("Connected:", cA:GetFullName(), "->", cB:GetFullName())
end

--[SKIP DUBLICATES / VALIDATE COUPLER]--
local function setupCoupler(coupler)
	if coupler:GetAttribute("CouplerSetup") then 
		return 
	end
	
	coupler:SetAttribute("CouplerSetup", true)

	coupler.Touched:Connect(function(hit)
		
		if not isCoupler(hit) or hit == coupler or coupler.Parent == hit.Parent then 
			return 
		end
		
		if findConnection(coupler) or findConnection(hit) then 
			return 
		end
		
		if not isValidPair(coupler, hit) then 
			return 
		end

		local player = getOccupantPlayer()
		
		if not player then 
			return 
		end

		--[CHECKS PENDING COUPLES]--
		if pendingCouple then
			local pA, pB = pendingCouple.couplerA, pendingCouple.couplerB
			
			if (pA == coupler and pB == hit) or (pA == hit and pB == coupler) then 
				return 
			end
		end

		pendingCouple = { couplerA = coupler, couplerB = hit }
		Couple:FireClient(player, true)
	end)
end

--[DOES THEY EXSIST?]--
for _, item in Workspace:GetDescendants() do
	if isCoupler(item) then setupCoupler(item) end
end

--[REAL TIME CHECKS - FOR NEW COUPLES]--
Workspace.DescendantAdded:Connect(function(item)
	if isCoupler(item) then setupCoupler(item) end
end)

--[DRIVER STATUS]--
if Seat then
	Seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		
		--[HIDE UI FOR PREVIOUS DRIVER]--
		if prevDriver then
			Couple:FireClient(prevDriver, false)
			UnCoupleStack:FireClient(prevDriver, false)
			prevDriver = nil
		end
		
		--[SHOW UI FOR NEW DRIVER]--
		local player = getOccupantPlayer()
		if player then
			prevDriver = player
			if pendingCouple then 
				Couple:FireClient(player, true) 
			end
			
			UnCoupleStack:FireClient(player, #connections > 0)
		end
	end)
end

--[REAL TIME - DISTANCE VALIDATIONS]--
task.spawn(function()
	
	while true do
		task.wait(0.5)
		
		if pendingCouple and not isValidPair(pendingCouple.couplerA, pendingCouple.couplerB, 10) then
			pendingCouple = nil
			
			local player = getOccupantPlayer()
			
			if player then 
				Couple:FireClient(player, false) 
				
			end
		end
	end
end)

--[IS TRAIN STOPPED ?]--
local function isTrainStopped()
	local primaryPart = Chassis and Chassis.PrimaryPart
	if not primaryPart then return true end -- якщо немає що перевіряти, не блокуємо

	local velocity = primaryPart.AssemblyLinearVelocity
	return velocity.Magnitude < 1 -- поріг, наприклад 1 stud/сек — можна підкрутити
end

--[CLIENT REQUEST PROCCESING]--

--[ COUPLE REQUEST]--
Couple.OnServerEvent:Connect(function(player)
	if player ~= getOccupantPlayer() or not pendingCouple then return end

	local cA, cB = pendingCouple.couplerA, pendingCouple.couplerB
	if isValidPair(cA, cB, 5) then
		connectCouplers(cA, cB)
		UnCoupleStack:FireClient(player, true)
	end

	pendingCouple = nil
	Couple:FireClient(player, false)
end)

--[ UNCOUPLE REQUEST ]--
UnCoupleStack.OnServerEvent:Connect(function(player)
	if player ~= getOccupantPlayer() or #connections == 0 then return end
	local conn = table.remove(connections)
	if conn and conn.rod then conn.rod:Destroy() end
	UnCoupleStack:FireClient(player, #connections > 0)
end)

UnCoupleZone.OnServerEvent:Connect(function(player, targetCoupler)
	if not targetCoupler or not isCoupler(targetCoupler) then return end
	if not isTrainStopped() then return end

	local index, conn = findConnection(targetCoupler)
	if not conn then return end

	conn.rod:Destroy()
	table.remove(connections, index)
	UnCoupleZone:FireClient(player, false, targetCoupler)
end)
