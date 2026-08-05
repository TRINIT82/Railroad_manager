local loco = workspace.Chassis.loco_coupler
local car = workspace.ChassisCopy.car_coupler

local Couple = game.ReplicatedStorage:WaitForChild("Couple")
local UnCouple = game.ReplicatedStorage:WaitForChild("UnCouple")

local Seat = workspace.Chassis.DriverSeat


local function getOccupantPlayer()
	if Seat.Occupant and Seat.Occupant.Parent then
		return game.Players:GetPlayerFromCharacter(Seat.Occupant.Parent)
	end
	return nil
end

local function connectCouplers()
	
	local player = getOccupantPlayer()
	
	local attach0 = loco:FindFirstChild("CouplerAttachment") or Instance.new("Attachment", loco)
	attach0.Name = "CouplerAttachment"
	
	local attach1 = car:FindFirstChild("CouplerAttachment") or Instance.new("Attachment", car)
	attach1.Name = "CouplerAttachment"
	
	local rod = Instance.new("RodConstraint")
	
	rod.Attachment0 = attach0
	rod.Attachment1 = attach1
	
	rod.Length = 5
	rod.Visible = true
	rod.Thickness = 0.5
	rod.Parent = loco
	rod.Name = "CouplerWeld"
	
	print("Connected couplers")
	
	if player then
		UnCouple:FireClient(player, true)
	end
	
end

local function touchEvent()
	
	loco.Touched:Once(function(hit)

		print("Hit Detected", hit.Name)

		if hit == car then
			local player = getOccupantPlayer()
			
			Couple:FireClient(player, true)
			--connectCouplers()
		end
	end)
end

local function detachCouplers()
	local weld = loco:FindFirstChild("CouplerWeld")
	
	if weld then
		weld:Destroy()
	end
end

touchEvent()

Couple.OnServerEvent:Connect(function(player)
	
	connectCouplers()
	Couple:FireClient(player, false)
end)

UnCouple.OnServerEvent:Connect(function(player)
	
	detachCouplers()
	
	UnCouple:FireClient(player, false)
	
	touchEvent()
end)
