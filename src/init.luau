--!strict

local Players = game:GetService("Players") :: Players

local RigHeight = require(script.RigHeight)
local HumanoidDescriptionHelper = require(script.HumanoidDescriptionHelper)

local INCLUDE_ROOT_PART = false

local RthroScaleNormalizer = {}

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

local function setHeight(character: Model, retainMass: boolean, targetHeight: number)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local head = character:WaitForChild("Head") :: BasePart
	local hrp = humanoid.RootPart :: BasePart

	local floorCF = hrp.CFrame * CFrame.new(0, -(hrp.Size.Y / 2 + humanoid.HipHeight), 0)

	local height = RigHeight.get(character, INCLUDE_ROOT_PART)
	local scale = (targetHeight / height) * readValueBase(humanoid, "BodyHeightScale", 1)

	local headMesh = head:FindFirstChildWhichIsA("SpecialMesh")
	local isFileMesh = false

	if headMesh then
		isFileMesh = (headMesh.MeshType == Enum.MeshType.FileMesh)
	end

	local accessories = {}
	for _, accessory in pairs(character:GetChildren()) do
		if accessory:IsA("Accessory") then
			local handle = accessory:FindFirstChildWhichIsA("BasePart") :: BasePart
			local weld = handle:FindFirstChild("AccessoryWeld") :: Weld
			weld:Destroy()
			accessory.Parent = nil
			accessories[accessory] = true
		end
	end

	if headMesh then
		matchHeadToMesh(head, headMesh)
	end

	for _, child in character:GetDescendants() do
		if child:IsA("Motor6D") then
			local p0 = child.C0.Position
			local p1 = child.C1.Position
			child.C0 = (child.C0 - p0) + p0 * scale
			child.C1 = (child.C1 - p1) + p1 * scale
		elseif child:IsA("Attachment") then
			child.Position = child.Position * scale

			local originalPosition = child:FindFirstChild("OriginalPosition") :: Vector3Value
			originalPosition.Value = originalPosition.Value * scale
		elseif child.Name == "OriginalSize" and child:IsA("Vector3Value") then
			local parent = child.Parent :: Instance

			if parent:IsA("BasePart") then
				local prevMass = parent:GetMass()
				parent.Size = parent.Size * scale
				child.Value = child.Value * scale

				if retainMass then
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
				for _, v3 in parent:GetChildren() do
					if v3:IsA("Vector3Value") and v3 ~= child then
						v3.Value = v3.Value * scale
					end
				end

				if isFileMesh and parent:IsA("SpecialMesh") then
					parent.Scale = parent.Scale * scale
					child.Value = child.Value * scale
				end
			end
		end
	end

	for accessory, _ in accessories do
		local handle = accessory:FindFirstChildWhichIsA("BasePart") :: BasePart
		local originalSize = handle:FindFirstChild("OriginalSize") :: Vector3Value
		originalSize.Value = originalSize.Value * scale
		humanoid:AddAccessory(accessory)
	end

	humanoid.HipHeight = humanoid.HipHeight * scale
	hrp.CFrame = floorCF * CFrame.new(0, hrp.Size.Y / 2 + humanoid.HipHeight, 0)
end

-- Public

function RthroScaleNormalizer.byHeight(character: Model, targetHeight: number)
	setHeight(character, true, targetHeight)
end

function RthroScaleNormalizer.byClassicScale(character: Model, scale: number)
	setHeight(character, true, RigHeight.getDefault() * scale)
end

--

return RthroScaleNormalizer
