local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Knit = require(Packages.Knit)
local AnimationComponent = require(Assets.Components.AnimationComponent)
local FrameOpenComponent = require(Assets.Components.FrameOpenComponent)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local MainGui = PlayerGui:WaitForChild("MainGui")

local GuiController = Knit.CreateController {
    Name = "GuiController",
}

function GuiController:InitSideButtons()
    for _,Button in pairs(CollectionService:GetTagged("SideButtons")) do
        AnimationComponent.new(Button)
            :Init(nil,function()
                local Gui = Button:FindFirstChild("Type")
                if Gui and Gui.Value then
                    Gui = Gui.Value
                    if not self.CurrentFrame or self.CurrentFrame ~= Gui then
                        self.CurrentFrame = Gui
                        if self.FrameComponents[Gui] then
                            self.FrameComponents[Gui]:Open()
                        else
                            local FrameComponent = FrameOpenComponent.new(Gui)
                            self.FrameComponents[Gui] = FrameComponent
                            FrameComponent:Open()
                        end
                    elseif self.CurrentFrame == Gui then
                        if self.FrameComponents[Gui] then
                            self.FrameComponents[Gui]:Close()
                        end
                    end
                end
            end)
    end
end

function GuiController:KnitInit()
    self.SummonService = Knit.GetService("SummonService")
    self.DataController = Knit.GetController("DataController")

    self.CurrentFrame = nil
    self.FrameComponents = {}

    self:InitSideButtons()

    self.SummonService.ShuffleTime:Connect(function(remainingTime)
        print("Time until next shuffle: ", remainingTime)
    end)

    task.wait(4)

    self.SummonService:Summon(5)

    while task.wait(1) do
        self.SummonService:GetCurrentTowers():andThen(function(Towers)
            if Towers then
                print("Current Towers: ", Towers)
            end
        end)
    end
end

function GuiController:KnitStart()
    
end

return GuiController