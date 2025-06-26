local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Knit = require(Packages.Knit)

Knit:Start():andThen(
    function()
        warn("Knit started successfully! {" .. Knit.Version .. "}")
    end
):catch(
    function(err)
        warn("Knit failed to start: " .. tostring(err))
    end
)