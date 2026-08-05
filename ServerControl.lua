local Seat = script.Parent
local Train = script.Parent.Parent.Parent
local isScript = false
 
Seat.Changed:Connect(function()
    if Seat.Occupant ~= nil then
        local player = game.Players:GetPlayerFromCharacter(Seat.Occupant.Parent)
        if player then
            if isScript == false then
                controlscript = script.LocalControl:Clone()
                controlscript.Parent = player.PlayerGui
                controlscript.Enabled = true
                controlscript.Train.Value = Train
                isScript = true
            end
        end
    else
        controlscript:Destroy()
        isScript = false
    end
end)
