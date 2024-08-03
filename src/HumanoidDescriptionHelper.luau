--!strict

local Players = game:GetService("Players")
local AvatarEditorService = game:GetService("AvatarEditorService")

export type HumanoidDescriptionProperties = {
	-- accessories
	BackAccessory: string?,
	FaceAccessory: string?,
	FrontAccessory: string?,
	HairAccessory: string?,
	HatAccessory: string?,
	NeckAccessory: string?,
	ShouldersAccessory: string?,
	WaistAccessory: string?,

	-- animation
	ClimbAnimation: number?,
	FallAnimation: number?,
	IdleAnimation: number?,
	JumpAnimation: number?,
	MoodAnimation: number?,
	RunAnimation: number?,
	SwimAnimation: number?,
	WalkAnimation: number?,

	-- body colors
	HeadColor: Color3?,
	LeftArmColor: Color3?,
	LeftLegColor: Color3?,
	RightArmColor: Color3?,
	RightLegColor: Color3?,
	TorsoColor: Color3?,

	-- body parts
	Face: number?,
	Head: number?,
	LeftArm: number?,
	LeftLeg: number?,
	RightArm: number?,
	RightLeg: number?,
	Torso: number?,

	-- clothes
	GraphicTShirt: number?,
	Pants: number?,
	Shirt: number?,

	-- scale
	BodyTypeScale: number?,
	DepthScale: number?,
	HeadScale: number?,
	HeightScale: number?,
	ProportionScale: number?,
	WidthScale: number?,
}

local HumanoidDescriptionHelper = {}

function HumanoidDescriptionHelper.fromUserId(userId: number)
	return Players:GetHumanoidDescriptionFromUserId(userId)
end

function HumanoidDescriptionHelper.fromPlayer(player: Player)
	return HumanoidDescriptionHelper.fromUserId(player.CharacterAppearanceId)
end

function HumanoidDescriptionHelper.fromProperties(properties: HumanoidDescriptionProperties)
	local description = Instance.new("HumanoidDescription")
	local castedProperties = properties :: { [string]: any }
	for property, value in castedProperties do
		(description :: any)[property] = value
	end
	return description
end

function HumanoidDescriptionHelper.fromBundle(bundleId: number): HumanoidDescription?
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
		return Players:GetHumanoidDescriptionFromOutfitId(itemId)
	end

	return nil
end

return HumanoidDescriptionHelper
