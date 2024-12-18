--!strict

local Players = game:GetService("Players") :: Players

local Packages = script.Parent.Parent
local Deque = require(Packages.Deque)

local CharacterHelper = {}
local cachedClassicRigHeight: number?

local INCLUDE_ROOT_PART_IN_HEIGHT_MEASUREMENT = false

-- Private

local function getAccurateSize(part: BasePart)
	-- potential bug on Roblox's end means we need this hacky solution to read a mesh part's accurate size
	-- https://devforum.roblox.com/t/avatar-body-parts-dont-match-the-size-listed-in-the-explorer/3101124

	if not part:IsA("MeshPart") then
		return part.Size
	end

	local tempModel = Instance.new("Model")
	local meshPart = part:Clone()
	meshPart:ClearAllChildren()
	meshPart.Parent = tempModel

	local extents = tempModel:GetExtentsSize()
	tempModel:Destroy()

	return extents
end

local function getCorners(cframe: CFrame, size: Vector3)
	local corners = {}
	for i = 0, 7 do
		-- stylua: ignore
		local offset = Vector3.new(
			2 * (math.floor(i / 4) % 2) - 1,
			2 * (math.floor(i / 2) % 2) - 1,
			2 * (i % 2) - 1
		)

		table.insert(corners, cframe * (size * offset * 0.5))
	end
	return corners
end

local function getBodyPartMotorsByPart0(character: Model, humanoid: Humanoid, rootPart: BasePart)
	local bodyPartSet = {}
	local bodyPartMotorsByPart0 = {}
	for _, bodyPart in character:GetChildren() do
		if bodyPart:IsA("BasePart") and (bodyPart == rootPart or humanoid:GetBodyPartR15(bodyPart)) then
			bodyPartSet[bodyPart] = true
			bodyPartMotorsByPart0[bodyPart] = {}
		end
	end

	for bodyPart, _ in bodyPartSet do
		for _, motor in bodyPart:GetChildren() do
			if motor:IsA("Motor6D") then
				local part0 = motor.Part0
				local part1 = motor.Part1

				if part0 and part1 and bodyPartSet[part0] and bodyPartSet[part1] then
					table.insert(bodyPartMotorsByPart0[part0], motor)
				end
			end
		end
	end

	return bodyPartMotorsByPart0
end

-- Public

function CharacterHelper.getHeight(character: Model)
	-- this function must be deterministic in the sense that it can be called on
	-- a character that is being actively animated or hasn't been parented to the data-model yet
	-- as such we must calculate this by using the motors in hrp object space without applying the transform property

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	local rootPart = humanoid and humanoid.RootPart

	assert(humanoid, "Cannot get the rig height because it's missing a humanoid.")
	assert(rootPart, "Cannot get the rig height because it's missing a root part.")

	local bodyPartMotorsByPart0 = getBodyPartMotorsByPart0(character, humanoid, rootPart)

	local stack = Deque.raw({ {
		part0 = rootPart,
		part0CF = CFrame.identity,
	} })

	local maxHeight = nil
	while stack:getLength() > 0 do
		local popped = stack:popBack()

		if INCLUDE_ROOT_PART_IN_HEIGHT_MEASUREMENT or popped.part0 ~= rootPart then
			local size = getAccurateSize(popped.part0)
			for i, corner in getCorners(popped.part0CF, size) do
				if not maxHeight or corner.Y > maxHeight then
					maxHeight = corner.Y
				end
			end
		end

		for _, joint in bodyPartMotorsByPart0[popped.part0] do
			-- part0 * c0 == part1 * c1
			-- part0 * c0 * c1:Inverse() == part1
			local part0CF = popped.part0CF * joint.C0 * joint.C1:Inverse()

			stack:pushBack({
				part0 = joint.Part1 :: BasePart,
				part0CF = part0CF,
			})
		end
	end

	return humanoid.HipHeight + rootPart.Size.Y / 2 + (maxHeight or 0)
end

function CharacterHelper.getClassicHeight()
	if not cachedClassicRigHeight then
		local description = Instance.new("HumanoidDescription")
		description.BodyTypeScale = 0

		local dummy = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
		local height = CharacterHelper.getHeight(dummy)
		dummy:Destroy()

		cachedClassicRigHeight = height
	end

	return cachedClassicRigHeight :: number
end

--

return CharacterHelper
