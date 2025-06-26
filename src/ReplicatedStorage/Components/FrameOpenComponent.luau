local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

--local Stats = ReplicatedStorage:WaitForChild("Stats")
--local Storage = ReplicatedStorage:WaitForChild("Storage")

local VisibleComponent = {}

function VisibleComponent.new(UI,info)
	local self = setmetatable({}, {
		__index = VisibleComponent
	})
	self.UI = UI
	self.OriSize = self.UI.Size

	self.VisibleTween = TweenService:Create(UI, info and info or not info and TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = self.OriSize
	})

	self.VisibleFalseTween = TweenService:Create(UI, info and info or not info and TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0,0)
	})
	
	self.UI.Size = UDim2.fromScale(0,0)
	self.UI.Visible = false
	return self
end

function VisibleComponent:Visible(value)
	if not self.UI then return end
	if value then
		self.UI.Visible = true
		--self.VisibleFalseTween:Cancel() do not cancle it breaks!!!
		self.VisibleTween:Play()
		self.VisibleTween.Completed:Wait()
	else
		--self.VisibleTween:Cancel() same for this one too
		self.VisibleFalseTween:Play()
		self.VisibleFalseTween.Completed:Wait()
		self.UI.Visible = false
	end
end

function VisibleComponent:destroy()
	if self.VisibleTween then
		self.VisibleTween:Cancel()
		self.VisibleTween:Destroy()
		self.VisibleTween = nil
	end

	if self.VisibleFalseTween then
		self.VisibleFalseTween:Cancel()
		self.VisibleFalseTween:Destroy()
		self.VisibleFalseTween = nil
	end

	setmetatable(self,nil)
end

return VisibleComponent
