--!strict

if false then
	require(script.Debug)
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.DevPackages.TestEZ)

TestEZ.TestBootstrap:run({
	ReplicatedStorage.Packages.RthroScaler,
})
