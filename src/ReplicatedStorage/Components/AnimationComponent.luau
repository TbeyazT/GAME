local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

--local Stats = ReplicatedStorage:WaitForChild("Stats")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local goodSignal = require(Assets.Modules.GoodSignal)

local AnimateComponent = {}

_G.ActiveFrame = nil

function AnimateComponent.new(UI)
	local self = setmetatable({}, {
		__index = AnimateComponent
	})

	self.UI = UI
	self.OriSize = self.UI.Size

	self.HoverTween = TweenService:Create(UI, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(self.UI.Size.X.Scale * 1.1, self.UI.Size.Y.Scale * 1.1)
	})

	self.HoverLeaveTween = TweenService:Create(UI, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(self.OriSize.X.Scale, self.OriSize.Y.Scale)
	})

	self.MouseDownTween = TweenService:Create(UI, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(self.UI.Size.X.Scale * 0.8, self.UI.Size.Y.Scale * 0.8)
	})

	self.MouseUpTween = TweenService:Create(UI, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(self.OriSize.X.Scale, self.OriSize.Y.Scale)
	})

	self.Connections = {}

	return self
end

function AnimateComponent:Hover()
	self.HoverTween:Play()
	local hoverSound = Assets.Sounds.UI:FindFirstChild("Hover")
	if hoverSound then
		hoverSound:Play()
	end
end

function AnimateComponent:UnHover()
	self.HoverLeaveTween:Play()
end

function AnimateComponent:MouseDown()
	if self.UI:IsA("GuiButton") then
		self.MouseDownTween:Play()
	end
end

function AnimateComponent:MouseUp()
	if self.UI:IsA("GuiButton") then
		self.MouseUpTween:Play()
		local clickSound = Assets.Sounds.UI:FindFirstChild("Click")
		if clickSound then
			clickSound:Play()
		end
	end
end

function AnimateComponent:Init(KeyCode:Enum.KeyCode,func)
	for i, connection in ipairs(self.Connections) do
		connection:Disconnect()
		self.Connections[i] = nil
	end
	self.Connections = {}
	table.insert(self.Connections, self.UI.MouseEnter:Connect(function()
		self:Hover()
	end))

	table.insert(self.Connections, self.UI.MouseLeave:Connect(function()
		self:UnHover()
	end))

	if self.UI:IsA("GuiButton") then
		table.insert(self.Connections, self.UI.MouseButton1Down:Connect(function()
			self:MouseDown()
		end))

		table.insert(self.Connections, self.UI.MouseButton1Up:Connect(function()
			self:MouseUp()
			if func and type(func) == "function" then
				func()
			end
		end))
	end

	if KeyCode then
		table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.KeyCode == KeyCode then
				self:MouseDown()
			end
		end))

		table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input, gpe)
			if gpe then return end
			if input.KeyCode == KeyCode then
				self:MouseUp()
				if func and type(func) == "function" then
					func()
				end
			end
		end))
	end
end

function AnimateComponent:destroy()
	for i, connection in ipairs(self.Connections) do
		connection:Disconnect()
		self.Connections[i] = nil
	end
	self.Connections = {}

	if self.HoverTween then
		self.HoverTween:Cancel()
		self.HoverTween:Destroy()
		self.HoverTween = nil
	end

	if self.HoverLeaveTween then
		self.HoverLeaveTween:Cancel()
		self.HoverLeaveTween:Destroy()
		self.HoverLeaveTween = nil
	end

	if self.MouseDownTween then
		self.MouseDownTween:Cancel()
		self.MouseDownTween:Destroy()
		self.MouseDownTween = nil
	end

	if self.MouseUpTween then
		self.MouseUpTween:Cancel()
		self.MouseUpTween:Destroy()
		self.MouseUpTween = nil
	end
	
	self.UI.Size = self.OriSize
	
	setmetatable(self,nil)
end

return AnimateComponent
