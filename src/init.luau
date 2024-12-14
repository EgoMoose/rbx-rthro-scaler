--!strict

local RunService = game:GetService("RunService")

local CharacterHelper = require(script.CharacterHelper)

local RthroScaler = {}
local isMassRetained = true

-- Private

local function readValueBase<T>(parent: Instance, name: string, default: T): T
	local found = (parent:FindFirstChild(name) :: any) :: { Value: T? }?
	return found and found.Value or default
end

local function matchHeadToMesh(head: BasePart, headMesh: SpecialMesh)
	for _, child in head:GetChildren() do
		if child:IsA("Attachment") and not headMesh:FindFirstChild(child.Name) then
			local vec3Copy = Instance.new("Vector3Value")
			vec3Copy.Name = child.Name
			vec3Copy.Value = child.Position
			vec3Copy.Parent = headMesh
		end
	end

	local partScaleType = head:FindFirstChild("AvatarPartScaleType")
	if partScaleType and not headMesh:FindFirstChild("AvatarPartScaleType") then
		partScaleType:Clone().Parent = headMesh
	end
end

local function setHeight(character: Model, currentHeight: number, height: number)
	local head = character:FindFirstChild("Head") :: BasePart?
	local humanoid = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid?
	local rootPart = humanoid and humanoid.RootPart

	assert(head, "Unable to find Head.")
	assert(humanoid, "Unable to find Humanoid.")
	assert(rootPart, "Unable to find Humanoid.RootPart.")

	local floorCF = rootPart.CFrame * CFrame.new(0, -(humanoid.HipHeight + rootPart.Size.Y / 2), 0)
	local scale = (height / currentHeight) * readValueBase(humanoid, "BodyHeightScale", 1)

	local headMesh = head:FindFirstChildWhichIsA("SpecialMesh")
	local isFileMesh = if headMesh then headMesh.MeshType == Enum.MeshType.FileMesh else false

	if headMesh then
		matchHeadToMesh(head, headMesh)
	end

	-- remove all accessories and store for later
	local accessories = {}
	for _, accessory in character:GetChildren() do
		if accessory:IsA("Accessory") then
			local handle = accessory:FindFirstChildWhichIsA("BasePart") :: BasePart?
			local originalSize = handle and handle:FindFirstChild("OriginalSize") :: Vector3Value?
			local weld = handle and handle:FindFirstChild("AccessoryWeld") :: Weld?

			if handle and originalSize and weld then
				weld:Destroy()
				accessory.Parent = nil
				accessories[accessory] = originalSize
			end
		end
	end

	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Motor6D") then
			descendant.C0 = descendant.C0.Rotation + descendant.C0.Position * scale
			descendant.C1 = descendant.C1.Rotation + descendant.C1.Position * scale
		elseif descendant:IsA("Attachment") then
			descendant.Position = descendant.Position * scale

			local originalPosition = descendant:FindFirstChild("OriginalPosition") :: Vector3Value?
			if originalPosition then
				originalPosition.Value = originalPosition.Value * scale
			end
		elseif descendant:IsA("Vector3Value") and descendant.Name == "OriginalSize" then
			local parent = descendant.Parent :: Instance

			if parent:IsA("BasePart") then
				local prevMass = parent:GetMass()

				parent.Size = parent.Size * scale
				descendant.Value = descendant.Value * scale

				if isMassRetained then
					local newMass = parent:GetMass()
					local physicalProperties = parent.CurrentPhysicalProperties
					local volume = newMass / physicalProperties.Density
					local newDensity = prevMass / volume

					parent.CustomPhysicalProperties = PhysicalProperties.new(
						newDensity,

						physicalProperties.Friction,
						physicalProperties.Elasticity,
						physicalProperties.FrictionWeight,
						physicalProperties.ElasticityWeight
					)
				end
			elseif headMesh and parent == headMesh then
				local headPart = parent.Parent :: Instance
				for _, child in parent:GetChildren() do
					if child:IsA("Vector3Value") then
						local found = headPart:FindFirstChild(child.Name)
						if found and found:IsA("Attachment") then
							child.Value = child.Value * scale
						end
					end
				end

				if isFileMesh and parent:IsA("SpecialMesh") then
					parent.Scale = parent.Scale * scale
					descendant.Value = descendant.Value * scale
				end
			end
		end
	end

	-- re-apply all the accessories scaled
	for accessory, originalSize in accessories do
		originalSize.Value = originalSize.Value * scale
		humanoid:AddAccessory(accessory)
	end

	humanoid.HipHeight = humanoid.HipHeight * scale
	rootPart.CFrame = floorCF * CFrame.new(0, rootPart.Size.Y / 2 + humanoid.HipHeight, 0)

	if RunService:IsClient() then
		humanoid:BuildRigFromAttachments()
	end
end

-- Public

--[=[
	Scales the provided character such that the tallest part in the model has a maximum height of `height`.

	@param character Model -- The target character model.
	@param height number -- The height in studs to set.
]=]
function RthroScaler.raw(character: Model, height: number)
	local currentHeight = CharacterHelper.getHeight(character)
	setHeight(character, currentHeight, height)
end

--[=[
	Scales the provided character relative to classic blocky avatar height.

	@param character Model -- The target character model.
	@param scale number -- Percentage of the classic height.
]=]
function RthroScaler.classic(character: Model, scale: number)
	local currentHeight = CharacterHelper.getHeight(character)
	local classicHeight = CharacterHelper.getClassicHeight() * scale
	setHeight(character, currentHeight, classicHeight)
end

--[=[
	Scales the provided character relative to its current height.

	@param character Model -- The target character model.
	@param scale number -- Percentage of the current height.
]=]
function RthroScaler.relative(character: Model, scale: number)
	local currentHeight = CharacterHelper.getHeight(character)
	local scaledHeight = currentHeight * scale
	setHeight(character, currentHeight, scaledHeight)
end

--[=[
	Returns if the mass of a character is retained or not in the scaling process.

	@return boolean
]=]
function RthroScaler.isMassRetained()
	return isMassRetained
end

--[=[
	Sets if the mass of a character is retained or not in the scaling process.

	@param retained boolean
]=]
function RthroScaler.setMassRetained(retained: boolean)
	isMassRetained = not not retained
end

--[=[
	Returns the height of the provided character model.

	@param character Model -- The target character model.
	@return number
]=]
RthroScaler.getHeight = CharacterHelper.getHeight

--[=[
	Returns the height of a classic scaled character.

	@return number
]=]
RthroScaler.getClassicHeight = CharacterHelper.getClassicHeight

--

return RthroScaler
