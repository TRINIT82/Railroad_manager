print("Economy Intialized")
local Player = game:GetService("Players")

local function onPlayerJoin(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = leaderstats
end

--[JOIN EVENT]--
Player.PlayerAdded:Connect(onPlayerJoin)

--[CURRENT PLAYERS]--
for _, player in Player:GetPlayers() do
	onPlayerJoin(player)
end
