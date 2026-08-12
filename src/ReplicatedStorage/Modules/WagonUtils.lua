local WagonUtils = {}

--[ WAGON TYPE ]--
function WagonUtils.getWagonType(coupler)
	local wagon = coupler.Parent

	return wagon and wagon:GetAttribute("WagonType")
end

--[ CHECK IF COUPLER IS PART OF TRAIN ]--
function WagonUtils.isPartOfTrain(coupler, Chassis, connections)
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

--[GET NEXT EMPTY WAGON]--
function WagonUtils.getNextEmptyWagon(detectZone, wagons)
	local partsInZone = workspace:GetPartsInPart(detectZone)
	local zoneType = detectZone:GetAttribute("LoadType")

	for _, wagon in ipairs(wagons) do
		local base = wagon:FindFirstChild("Base")
		local wagonType = wagon:GetAttribute("WagonType")

		if base and table.find(partsInZone, base) and wagonType == zoneType then
			
			local currentLoad = wagon:GetAttribute("CurrentLoad")
			local maxLoad = wagon:GetAttribute("MaxCapacity")

			if currentLoad < maxLoad then
				return wagon
			end
		end
	end

	return nil
end

--[GET NEXT LOADED WAGON]--
function WagonUtils.getNextLoadedWagon(detectZone, wagons)
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

return WagonUtils
