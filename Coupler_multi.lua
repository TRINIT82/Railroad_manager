local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Couple = ReplicatedStorage:WaitForChild("Couple")
local UnCouple = ReplicatedStorage:WaitForChild("UnCouple")

local Chassis = Workspace:FindFirstChild("Chassis")
local Seat = Chassis and Chassis:FindFirstChild("DriverSeat")

local connections = {}
local pendingCouple = nil
local prevDriver = nil

-- Отримання водія
local function getOccupantPlayer()
	local occupant = Seat and Seat.Occupant
	return occupant and occupant.Parent and Players:GetPlayerFromCharacter(occupant.Parent)
end

local function isCoupler(part)
	return part:IsA("BasePart") and part.Name:lower():find("coupler") ~= nil
end

local function findConnection(coupler)
	for i, conn in ipairs(connections) do
		if conn.couplerA == coupler or conn.couplerB == coupler then return i, conn end
	end
end

local function isPartOfTrain(coupler)
	if Chassis and coupler.Parent == Chassis then return true end
	for _, conn in ipairs(connections) do
		if conn.couplerA.Parent == coupler.Parent or conn.couplerB.Parent == coupler.Parent then
			return true
		end
	end
	return false
end

-- Створення або пошук Attachment
local function getAttachment(part)
	local attach = part:FindFirstChild("CouplerAttachment")
	if not attach then
		attach = Instance.new("Attachment")
		attach.Name = "CouplerAttachment"
		attach.Parent = part
	end
	return attach
end

-- Перевірка відповідності пари та відстані
local function isValidPair(cA, cB, maxDist)
	if not (cA and cB and cA.Parent and cB.Parent) then return false end
	if maxDist and (cA.Position - cB.Position).Magnitude > maxDist then return false end
	return isPartOfTrain(cA) or isPartOfTrain(cB)
end

local function connectCouplers(cA, cB)
	local rod = Instance.new("RodConstraint")
	rod.Name = "CouplerWeld_" .. (#connections + 1)
	rod.Attachment0, rod.Attachment1 = getAttachment(cA), getAttachment(cB)
	rod.Length, rod.Thickness, rod.Visible = 5, 0.5, true
	rod.Parent = cA

	table.insert(connections, { couplerA = cA, couplerB = cB, rod = rod })
	print("Connected:", cA:GetFullName(), "->", cB:GetFullName())
end

-- Налаштування обробника для coupler-а
local function setupCoupler(coupler)
	if coupler:GetAttribute("CouplerSetup") then return end
	coupler:SetAttribute("CouplerSetup", true)

	coupler.Touched:Connect(function(hit)
		if not isCoupler(hit) or hit == coupler or coupler.Parent == hit.Parent then return end
		if findConnection(coupler) or findConnection(hit) then return end
		if not isValidPair(coupler, hit) then return end

		local player = getOccupantPlayer()
		if not player then return end

		-- Перевірка чи ця пара вже в pending
		if pendingCouple then
			local pA, pB = pendingCouple.couplerA, pendingCouple.couplerB
			if (pA == coupler and pB == hit) or (pA == hit and pB == coupler) then return end
		end

		pendingCouple = { couplerA = coupler, couplerB = hit }
		Couple:FireClient(player, true)
	end)
end

-- Ініціалізація існування та нових деталей
for _, item in Workspace:GetDescendants() do
	if isCoupler(item) then setupCoupler(item) end
end
Workspace.DescendantAdded:Connect(function(item)
	if isCoupler(item) then setupCoupler(item) end
end)

-- Відстеження водія
if Seat then
	Seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if prevDriver then
			Couple:FireClient(prevDriver, false)
			UnCouple:FireClient(prevDriver, false)
			prevDriver = nil
		end

		local player = getOccupantPlayer()
		if player then
			prevDriver = player
			if pendingCouple then Couple:FireClient(player, true) end
			UnCouple:FireClient(player, #connections > 0)
		end
	end)
end

-- Перевірка відстані між вагонами в реальному часі
task.spawn(function()
	while true do
		task.wait(0.5)
		if pendingCouple and not isValidPair(pendingCouple.couplerA, pendingCouple.couplerB, 10) then
			pendingCouple = nil
			local player = getOccupantPlayer()
			if player then Couple:FireClient(player, false) end
		end
	end
end)

-- Обробка подій від клієнта
Couple.OnServerEvent:Connect(function(player)
	if player ~= getOccupantPlayer() or not pendingCouple then return end

	local cA, cB = pendingCouple.couplerA, pendingCouple.couplerB
	if isValidPair(cA, cB, 5) then
		connectCouplers(cA, cB)
		UnCouple:FireClient(player, true)
	end

	pendingCouple = nil
	Couple:FireClient(player, false)
end)

UnCouple.OnServerEvent:Connect(function(player)
	if player ~= getOccupantPlayer() or #connections == 0 then return end

	local conn = table.remove(connections) -- Видаляє останній елемент
	if conn and conn.rod then
		conn.rod:Destroy()
		print("Disconnected:", conn.couplerA:GetFullName(), "<-", conn.couplerB:GetFullName())
	end

	UnCouple:FireClient(player, #connections > 0)
end)
