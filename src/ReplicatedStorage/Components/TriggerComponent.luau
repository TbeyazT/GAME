local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Player = Players.LocalPlayer

local GoodSignal = require(Assets.Modules.GoodSignal)

local HitPartComponent = {}

local activeComponents = {}
local runServiceConnection = nil

function HitPartComponent.new(part: BasePart)
	local self = setmetatable({}, {__index = HitPartComponent})
	self.part = part
	self.isTouched = false
	self.DumpTouchedSignal = nil
	self.onTouchedSignal = GoodSignal.new()
	self.onTouchEndedSignal = GoodSignal.new()

	table.insert(activeComponents, self)

	if not self.part:IsA("TouchTransmitter") then
		self.DumpTouchedSignal = self.part.Touched:Connect(function() end)
	end

	if not runServiceConnection then
		runServiceConnection = RunService.Heartbeat:Connect(HitPartComponent.updateAll)
	end

	return self
end

function HitPartComponent.updateAll()
	for _, component in ipairs(activeComponents) do
		component:checkProximity()
	end
end

function HitPartComponent:checkProximity()
	if not self.part then return end

	local touchingParts = self.part:GetTouchingParts()
	local isInProximity = false

	for _, touchingPart in ipairs(touchingParts) do
		if touchingPart:IsDescendantOf(Player.Character or Player.CharacterAdded:Wait()) then
			isInProximity = true
			break
		end
	end

	if isInProximity and not self.isTouched then
		self.isTouched = true
		self.onTouchedSignal:Fire()
		warn("touched")
	elseif not isInProximity and self.isTouched then
		self.isTouched = false
		self.onTouchEndedSignal:Fire()
	end
end

function HitPartComponent:destroy()
	for i, component in ipairs(activeComponents) do
		if component == self then
			table.remove(activeComponents, i)
			break
		end
	end
	
	self.onTouchedSignal:DisconnectAll()
	self.onTouchEndedSignal:DisconnectAll()
	if self.DumpTouchedSignal then
		self.DumpTouchedSignal:Disconnect()
	end
	setmetatable(self,nil)

	if #activeComponents == 0 and runServiceConnection then
		runServiceConnection:Disconnect()
		runServiceConnection = nil
	end
end

return HitPartComponent