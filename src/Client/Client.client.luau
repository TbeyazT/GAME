local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameVersion = "0.1.0"

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Knit = require(Packages.Knit)

Knit.AddControllersDeep(script.Parent.Controllers)

Knit:Start():andThen(
    function()
        warn("Knit started successfully! {" .. GameVersion .. "}")
    end
):catch(
    function(err)
        warn("Knit failed to start: " .. tostring(err))
    end
)