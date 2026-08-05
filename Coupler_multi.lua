local Couple = game.ReplicatedStorage:WaitForChild("Couple")
local UnCouple = game.ReplicatedStorage:WaitForChild("UnCouple")

local Seat = workspace:FindFirstChild("Chassis") and workspace.Chassis:FindFirstChild("DriverSeat")

-- Список усіх з'єднань: {{couplerA, couplerB, rod}, ...}
local connections = {}
-- Очікуване з'єднання (очікує натискання кнопки Couple)
local pendingCouple = nil

local function getOccupantPlayer()
	if Seat and Seat.Occupant and Seat.Occupant.Parent then
		return game.Players:GetPlayerFromCharacter(Seat.Occupant.Parent)
	end
	return nil
end

-- Перевіряє, чи частина є coupler-ом (за назвою)
local function isCoupler(part)
	return part:IsA("BasePart") and string.find(string.lower(part.Name), "coupler") ~= nil
end

-- Шукає з'єднання, в якому бере участь даний coupler
local function findConnection(coupler)
	for i, conn in ipairs(connections) do
		if conn.couplerA == coupler or conn.couplerB == coupler then
			return i, conn
		end
	end
	return nil
end

-- Перевіряє, чи це та сама пара coupler-ів (в будь-якому порядку)
local function isSamePair(a, b, c, d)
	return (a == c and b == d) or (a == d and b == c)
end

-- Перевіряє, чи coupler належить локомотиву або вагону, вже підключеному до потяга
local function isPartOfTrain(coupler)
	local locoModel = workspace:FindFirstChild("Chassis")
	if locoModel and coupler.Parent == locoModel then
		return true
	end

	-- Перевіряємо, чи модель цього coupler-а вже є в ланцюгу з'єднань
	local model = coupler.Parent
	for _, conn in ipairs(connections) do
		if conn.couplerA.Parent == model or conn.couplerB.Parent == model then
			return true
		end
	end
	return false
end

local function connectCouplers(couplerA, couplerB)
	local attach0 = couplerA:FindFirstChild("CouplerAttachment")
	if not attach0 then
		attach0 = Instance.new("Attachment")
		attach0.Name = "CouplerAttachment"
		attach0.Parent = couplerA
	end

	local attach1 = couplerB:FindFirstChild("CouplerAttachment")
	if not attach1 then
		attach1 = Instance.new("Attachment")
		attach1.Name = "CouplerAttachment"
		attach1.Parent = couplerB
	end

	local rod = Instance.new("RodConstraint")
	rod.Attachment0 = attach0
	rod.Attachment1 = attach1
	rod.Length = 5
	rod.Visible = true
	rod.Thickness = 0.5
	rod.Parent = couplerA
	rod.Name = "CouplerWeld_" .. #connections

	table.insert(connections, {
		couplerA = couplerA,
		couplerB = couplerB,
		rod = rod,
	})

	print("Connected:", couplerA:GetFullName(), "->", couplerB:GetFullName())
end

-- Налаштовує обробник дотику для coupler-а
local function setupCoupler(coupler)
	if coupler:GetAttribute("CouplerSetup") then return end
	coupler:SetAttribute("CouplerSetup", true)

	coupler.Touched:Connect(function(hit)
		if not isCoupler(hit) then return end
		if hit == coupler then return end
		-- Не з'єднувати coupler-и з однієї моделі (одного вагона)
		if coupler.Parent == hit.Parent then return end

		-- Якщо хоч один coupler вже з'єднаний — пропускаємо
		if findConnection(coupler) or findConnection(hit) then return end

		-- Дозволяємо з'єднання лише якщо хоч один coupler належить потягу
		if not isPartOfTrain(coupler) and not isPartOfTrain(hit) then return end

		-- Водій має бути в кабіні, щоб побачити кнопку
		local player = getOccupantPlayer()
		if not player then return end

		-- Якщо ця пара вже в очікуванні — не спамимо
		if pendingCouple and isSamePair(pendingCouple.couplerA, pendingCouple.couplerB, coupler, hit) then
			return
		end

		pendingCouple = {couplerA = coupler, couplerB = hit}
		Couple:FireClient(player, true)
	end)
end

-- Налаштувати всі існуючі coupler-и
for _, descendant in workspace:GetDescendants() do
	if isCoupler(descendant) then
		setupCoupler(descendant)
	end
end

-- Налаштовувати нові coupler-и, додані під час гри
workspace.DescendantAdded:Connect(function(descendant)
	if isCoupler(descendant) then
		setupCoupler(descendant)
	end
end)

-- Коли водій сідає в кабіну — показати кнопки, якщо є що з'єднувати/роз'єднувати
if Seat then
	Seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local player = getOccupantPlayer()
		if player then
			if pendingCouple then
				Couple:FireClient(player, true)
			end
			if #connections > 0 then
				UnCouple:FireClient(player, true)
			end
		end
	end)
end

-- Автоматично очищає pendingCouple, якщо coupler-и роз'їхалися
task.spawn(function()
	while true do
		task.wait(0.5)
		if pendingCouple then
			local cA = pendingCouple.couplerA
			local cB = pendingCouple.couplerB
			if not cA.Parent or not cB.Parent then
				pendingCouple = nil
			elseif (cA.Position - cB.Position).Magnitude > 10 then
				pendingCouple = nil
				local player = getOccupantPlayer()
				if player then
					Couple:FireClient(player, false)
				end
			end
		end
	end
end)

-- Гравець натиснув кнопку Couple
Couple.OnServerEvent:Connect(function(player)
	-- Тільки водій може з'єднувати вагони
	if player ~= getOccupantPlayer() then return end

	if pendingCouple then
		local cA = pendingCouple.couplerA
		local cB = pendingCouple.couplerB

		-- Перевіряємо, що обидва coupler-и ще існують
		if not cA.Parent or not cB.Parent then
			pendingCouple = nil
			Couple:FireClient(player, false)
			return
		end

		-- Перевіряємо, що coupler-и все ще близько один до одного
		local distance = (cA.Position - cB.Position).Magnitude
		if distance > 5 then
			pendingCouple = nil
			Couple:FireClient(player, false)
			return
		end

		-- Повторно перевіряємо, що хоч один coupler належить потягу
		if not isPartOfTrain(cA) and not isPartOfTrain(cB) then
			pendingCouple = nil
			Couple:FireClient(player, false)
			return
		end

		connectCouplers(cA, cB)
		pendingCouple = nil
		Couple:FireClient(player, false)
		UnCouple:FireClient(player, true)
	end
end)

-- Гравець натиснув кнопку UnCouple — роз'єднує останнє з'єднання
UnCouple.OnServerEvent:Connect(function(player)
	-- Тільки водій може роз'єднувати вагони
	if player ~= getOccupantPlayer() then return end

	if #connections > 0 then
		local idx = #connections
		local conn = connections[idx]
		if conn.rod then
			conn.rod:Destroy()
		end
		print("Disconnected:", conn.couplerA:GetFullName(), "<-", conn.couplerB:GetFullName())
		table.remove(connections, idx)
	end

	UnCouple:FireClient(player, false)

	-- Якщо ще є з'єднання — кнопка UnCouple лишається активною
	if #connections > 0 then
		UnCouple:FireClient(player, true)
	end
end)
