--!strict

local CharacterHelper = require(script.CharacterHelper)

local RthroScaler = {}
local isMassRetained = true

-- Private

local function setHeight(character: Model, currentHeight: number, height: number)
	local humanoid = character:FindFirstChildWhichIsA("Humanoid") :: Humanoid?
	local rootPart = humanoid and humanoid.RootPart

	assert(humanoid, "Unable to find Humanoid.")
	assert(rootPart, "Unable to find Humanoid.RootPart.")

	local floorCF = rootPart.CFrame * CFrame.new(0, -(humanoid.HipHeight + rootPart.Size.Y / 2), 0)

	local currentScale = character:GetScale()
	local fullHeight = currentHeight / currentScale
	local newScale = height / fullHeight

	local massByLimb = {}
	for _, limb in character:GetChildren() do
		if limb:IsA("BasePart") and humanoid:GetLimb(limb) then
			massByLimb[limb] = limb:GetMass()
		end
	end

	local walkSpeed = humanoid.WalkSpeed
	local jumpPower = humanoid.JumpPower
	local jumpHeight = humanoid.JumpHeight
	character:ScaleTo(newScale)
	humanoid.WalkSpeed = walkSpeed
	humanoid.JumpPower = jumpPower
	humanoid.JumpHeight = jumpHeight

	if isMassRetained then
		for limb, mass in massByLimb do
			local newMass = limb:GetMass()
			local physicalProperties = limb.CurrentPhysicalProperties
			local volume = newMass / physicalProperties.Density
			local newDensity = mass / volume

			limb.CustomPhysicalProperties = PhysicalProperties.new(
				newDensity,
				physicalProperties.Friction,
				physicalProperties.Elasticity,
				physicalProperties.FrictionWeight,
				physicalProperties.ElasticityWeight
			)
		end
	end

	rootPart.CFrame = floorCF * CFrame.new(0, rootPart.Size.Y / 2 + humanoid.HipHeight, 0)
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
