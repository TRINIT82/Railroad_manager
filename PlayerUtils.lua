local PlayerUtils = {}

local Players = game:GetService("Players")

function PlayerUtils.getOccupantPlayer(Seat)
	local occupant = Seat and Seat.Occupant
	return occupant and occupant.Parent and Players:GetPlayerFromCharacter(occupant.Parent)
end

return PlayerUtils
