local Seat = script.Parent
local Train = script.Parent.Parent.Parent
local LinearVelocity = Train.Chassis.Base.LinearVelocity
local Data = Train.Chassis.Data
local RunService = game:GetService("RunService")
local KeyBinds = game:GetService("ReplicatedStorage").Events.Keybinds

RunService.Heartbeat:Connect(function()
	if Data.Direction.Value == 1 then
		if Seat.Throttle > 0 then
			local speed = Seat.Throttle * 0.053
			LinearVelocity.LineVelocity = math.clamp(LinearVelocity.LineVelocity + speed, 0, 50)
		end
		if Seat.Throttle < 0 then
			local speed = Seat.Throttle * 0.053
			LinearVelocity.LineVelocity = math.clamp(LinearVelocity.LineVelocity + speed, 0, 50)
		end
	elseif Data.Direction.Value == 0 then
		if Seat.Throttle > 0 then
			local speed = Seat.Throttle * 0.053
			LinearVelocity.LineVelocity = math.clamp(LinearVelocity.LineVelocity - speed, -50, 0)
		end
		if Seat.Throttle < 0 then
			local speed = Seat.Throttle * 0.053
			LinearVelocity.LineVelocity = math.clamp(LinearVelocity.LineVelocity - speed, -50, 0)
		end
	end
end)

KeyBinds.OnServerEvent:Connect(function(player, keybind)
	if Seat.Occupant ~= nil then
		local plr = game:GetService("Players"):GetPlayerFromCharacter(Seat.Occupant.Parent)
		local case = {
			["R"] = function ()
				if Data.Direction.Value == 1 and LinearVelocity.LineVelocity == 0 then
					Data.Direction.Value = 0
					print("revers-")
				elseif Data.Direction.Value == 0 and LinearVelocity.LineVelocity == 0 then
					Data.Direction.Value = 1
					print("revers+")
				end
			end,
			["H"] = function ()
				if script.Parent.Horn.Playing == false then
					script.Parent.Horn:Play()
				end
			end,
		}
		if case [keybind] then
			case [keybind] ()
		end
	end
end)
