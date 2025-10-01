--!strict

if true then
	return
end

local Players = game:GetService("Players") :: Players

local RthroScaler = require(game.ReplicatedStorage.Packages.RthroScaler)

local uiStroke = Instance.new("UIStroke")
uiStroke.Parent = workspace

Players.LocalPlayer.CharacterAdded:Connect(function(character)
	uiStroke.Transparency = 1
	RthroScaler.classic(character, 1)

	uiStroke:GetPropertyChangedSignal("Transparency"):Connect(function()
		RthroScaler.classic(character, math.max(1E-3, uiStroke.Transparency))
	end)
end)
