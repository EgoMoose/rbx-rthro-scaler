--!strict

local Players = game:GetService("Players") :: Players
local AvatarEditorService = game:GetService("AvatarEditorService") :: AvatarEditorService

local RthroScaler = require(game.ReplicatedStorage.Packages.RthroScaler)

local function humanoidDescriptionFromBundle(bundleId: number): HumanoidDescription?
	local info = AvatarEditorService:GetItemDetails(bundleId, Enum.AvatarItemType.Bundle)
	local items = if info then info.BundledItems else {}

	local itemId: number?
	for _, item in items do
		if item.Type == "UserOutfit" then
			itemId = item.Id
			break
		end
	end

	if itemId and itemId > 0 then
		local description = Players:GetHumanoidDescriptionFromOutfitId(itemId)
		description.Name = info.Name
		return description
	end

	return nil
end

local function getDescription(player: Player)
	local description = assert(humanoidDescriptionFromBundle(319935), "Unable to load the bundle.")
	return description
end

local function scaleCharacter(character: Model)
	RthroScaler.classic(character, 1)
end

local function createDisplayDummies(player: Player)
	local simpleDescription = Instance.new("HumanoidDescription")
	simpleDescription.BodyTypeScale = 0
	local simpleDummy = Players:CreateHumanoidModelFromDescription(simpleDescription, Enum.HumanoidRigType.R15)

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

return {}
