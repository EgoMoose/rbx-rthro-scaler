--!strict

local Players = game:GetService("Players") :: Players
local AvatarEditorService = game:GetService("AvatarEditorService") :: AvatarEditorService

local MARGIN_OF_ERROR = 1E-4
local BUNDLES = { 5667, 474, 592, 370, 501, 3416, 338106, 319935, 389802, 393119, 382840, 295206, 512 }

local function humanoidDescriptionFromBundle(bundleId: number): HumanoidDescription?
	local info: { [any]: any }?
	local success = pcall(function()
		info = AvatarEditorService:GetItemDetails(bundleId, Enum.AvatarItemType.Bundle)
	end)

	if success and info then
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
	end

	return nil
end

return function()
	local RthroScaler = require(script.Parent)
	local CharacterHelper = require(script.Parent.CharacterHelper)

	for _, bundleId in BUNDLES do
		local description = assert(humanoidDescriptionFromBundle(bundleId), `Unable to load bundle from id: {bundleId}`)
		local dummyTemplate = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)

		describe(`[{bundleId}] - {description.Name}`, function()
			it("should .raw set height", function()
				local dummy = dummyTemplate:Clone()
				RthroScaler.raw(dummy, 10)

				expect(CharacterHelper.getHeight(dummy)).to.near(10, MARGIN_OF_ERROR)
				dummy:Destroy()
			end)

			it("should .relative set height", function()
				local dummy = dummyTemplate:Clone()
				local height = CharacterHelper.getHeight(dummy)
				RthroScaler.relative(dummy, 0.5)

				expect(CharacterHelper.getHeight(dummy)).to.near(height * 0.5, MARGIN_OF_ERROR)
				dummy:Destroy()
			end)

			it("should .classic set height", function()
				local dummy = dummyTemplate:Clone()
				RthroScaler.classic(dummy, 1)

				expect(CharacterHelper.getHeight(dummy)).to.near(CharacterHelper.getClassicHeight(), MARGIN_OF_ERROR)
				dummy:Destroy()
			end)
		end)
	end
end
