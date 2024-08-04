--!strict

local Players = game:GetService("Players") :: Players

local RthroScaler = require(script.Parent)
local HumanoidDescriptionHelper = require(script.Parent.HumanoidDescriptionHelper)

local function getDescription(player: Player)
	--local description = assert(HumanoidDescriptionHelper.fromBundle(5667), "Unable to load the bundle.")
	local description = assert(HumanoidDescriptionHelper.fromPlayer(player), "Unable to load the bundle.")
	return description
end

local function scaleCharacter(character: Model)
	RthroScaler.relative(character, 0.5)
end

local function createDisplayDummies(player: Player)
	local simpleDummy = Players:CreateHumanoidModelFromDescription(
		HumanoidDescriptionHelper.fromProperties({
			BodyTypeScale = 0,
		}),
		Enum.HumanoidRigType.R15
	)

	local bundleDummy = Players:CreateHumanoidModelFromDescription(getDescription(player), Enum.HumanoidRigType.R15)
	local scaledDummy = bundleDummy:Clone()
	scaleCharacter(scaledDummy)

	for i, dummy in { simpleDummy, scaledDummy, bundleDummy } do
		local humanoid = dummy:WaitForChild("Humanoid") :: Humanoid
		local rootPart = dummy:WaitForChild("HumanoidRootPart") :: BasePart
		rootPart.Color = Color3.new(1, 0, 0)
		rootPart.Transparency = 0.7
		rootPart.Anchored = true

		local floorOffset = humanoid.HipHeight + rootPart.Size.Y / 2
		dummy:PivotTo(CFrame.new(i * 5, floorOffset, 0))
		dummy.Parent = workspace
	end
end

return function()
	local animate = Instance.new("LocalScript")
	animate.Name = "Animate"
	-- animate.Parent = game.StarterPlayer.StarterCharacterScripts

	Players.CharacterAutoLoads = false
	Players.PlayerAdded:Connect(function(player)
		createDisplayDummies(player)

		while true do
			player:LoadCharacterWithHumanoidDescription(getDescription(player))

			if player.Character then
				scaleCharacter(player.Character)

				local humanoid = player.Character:WaitForChild("Humanoid") :: Humanoid
				humanoid.Died:Wait()
				task.wait(Players.RespawnTime)
			end
		end
	end)
end
