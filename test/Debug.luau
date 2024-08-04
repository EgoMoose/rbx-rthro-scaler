--!strict

local Players = game:GetService("Players") :: Players
local AvatarEditorService = game:GetService("AvatarEditorService") :: AvatarEditorService

local BUNDLE_ID = 451396
local SHOW_ROOT_PART = false
local DISPLAY_DISTANCE_TYPE = Enum.HumanoidDisplayDistanceType.Viewer

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
	local description = assert(humanoidDescriptionFromBundle(BUNDLE_ID), "Unable to load the bundle.")
	return description
end

local function scaleCharacter(character: Model)
	RthroScaler.classic(character, 1)
end

local function createDisplayDummies(player: Player)
	local simpleDescription = Instance.new("HumanoidDescription")
	simpleDescription.BodyTypeScale = 0
	local simpleDummy = Players:CreateHumanoidModelFromDescription(simpleDescription, Enum.HumanoidRigType.R15)
	local simplyDummyHumanoid = simpleDummy:WaitForChild("Humanoid") :: Humanoid
	simplyDummyHumanoid.DisplayDistanceType = DISPLAY_DISTANCE_TYPE
	simpleDummy.Name = "Classic"

	local bundleDummy = Players:CreateHumanoidModelFromDescription(getDescription(player), Enum.HumanoidRigType.R15)
	local bundleDummyHumanoid = bundleDummy:WaitForChild("Humanoid") :: Humanoid
	bundleDummyHumanoid.DisplayDistanceType = DISPLAY_DISTANCE_TYPE
	bundleDummy.Name = "Unscaled"

	local scaledDummy = bundleDummy:Clone()
	scaledDummy.Name = "RthroScaled"
	scaleCharacter(scaledDummy)

	for i, dummy in { bundleDummy, scaledDummy, simpleDummy } do
		local humanoid = dummy:WaitForChild("Humanoid") :: Humanoid
		local rootPart = dummy:WaitForChild("HumanoidRootPart") :: BasePart

		rootPart.Anchored = true
		rootPart.CastShadow = false

		if SHOW_ROOT_PART then
			rootPart.Color = Color3.new(1, 0, 0)
			rootPart.Transparency = 0.7
		end

		local floorOffset = humanoid.HipHeight + rootPart.Size.Y / 2
		dummy:PivotTo(CFrame.new(i * 5, floorOffset, 0))
		dummy.Parent = workspace
	end
end

local function spawnPlayerLoop(player: Player)
	while true do
		player:LoadCharacterWithHumanoidDescription(getDescription(player))

		if player.Character then
			scaleCharacter(player.Character)

			local humanoid = player.Character:WaitForChild("Humanoid") :: Humanoid
			humanoid.Died:Wait()
			task.wait(Players.RespawnTime)
		end
	end
end

local animate = Instance.new("LocalScript")
animate.Name = "Animate"
animate.Parent = game.StarterPlayer.StarterCharacterScripts

Players.CharacterAutoLoads = false
Players.PlayerAdded:Connect(function(player)
	createDisplayDummies(player)

	spawnPlayerLoop(player)
end)

return {}
