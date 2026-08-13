local PlayerUtils = {}

local Players = game:GetService("Players")

function PlayerUtils.getOccupantPlayer(Seat)
	local occupant = Seat and Seat.Occupant
	return occupant and occupant.Parent and Players:GetPlayerFromCharacter(occupant.Parent)
end

function PlayerUtils.setButtonState(event, buttonState, player, state)
	if buttonState[player] == state then 
		return 
	end

	buttonState[player] = state
	event:FireClient(player, state)
end

return PlayerUtils
