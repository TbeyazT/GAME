--[[
    File Purpose:
]]

-------------------------- Roblox Services --------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


-------------------------- Knit --------------------------
local Knit = require(ReplicatedStorage.Packages.Knit)

-------------------------- Util --------------------------
local Dumpster = require(ReplicatedStorage.Packages.Dumpster)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

-------------------------- Modul es --------------------------
local ReplicaController = require(ReplicatedStorage:WaitForChild("ReplicaController"))
--
-------------------------- Dependencies --------------------------

-------------------------- Constants --------------------------

-------------------------- Fields --------------------------
local DataController = Knit.CreateController {
    Name = "DataController",
}

-------------------------- Local Functions --------------------------

-------------------------- Lifetime Functions --------------------------
function DataController:KnitInit()
    ReplicaController.RequestData()
end

-------------------------- Public Functions --------------------------
-- Will get the value from the given key if it exists
function DataController:Get(player: Player, key: string): "Promise"
    return self:_getReplica(player):andThen(function(replica)
        local value: any = shared.Get(replica.Data, key)
        
        if value == nil then
            return Promise.reject(`Failed to index key: {key} for player: {player}`)
        end

        return Promise.resolve(value)
    end)
end

-- Fires when the Data is changed for the player
-- This can also be used to get the initial value of the data being retrieved
function DataController:Changed(player: Player, key: string, useInitialValue: boolean?): "Signal"
    local changedSignal = Signal.new()

    self:_getReplica(player):andThen(function(player_replica): ()
        player_replica:ListenToChange(key, function(new: any, old: any): ()
            changedSignal:Fire(new, old)
        end)

        if useInitialValue then
            self:Get(player, key):andThen(function(value: any)
                task.defer(function()
                    changedSignal:Fire(value)
                end)
            end)
        end
    end)

    return changedSignal
end
-------------------------- Private Functions --------------------------
-- Will find the player replica or attempt to yield for it without stopping the current thread (Uses Promises)
function DataController:_getReplica(player: Player)
    local playerReplica = ReplicaController.ReplicaClasses[tostring(player.UserId)]

    if not playerReplica then
        return self:_waitForReplica(player)
    end

    return Promise.resolve(playerReplica)
end

function DataController:_waitForReplica(player)
    local dumpster = Dumpster.new()

    dumpster:Add(function()
        dumpster = nil
    end)

    return Promise.defer(function(resolve)
        local playerReplica = ReplicaController.ReplicaClasses[tostring(player.UserId)]

        if playerReplica then
            return resolve(playerReplica)
        end

        dumpster:Add(ReplicaController.ReplicaOfClassCreated(tostring(player.UserId), resolve))
    end):tap(function()
        dumpster:Destroy()
    end):andThen(function(retrievedReplica)
        if retrievedReplica then
            return Promise.resolve(retrievedReplica)
        end

        return Promise.reject()
    end)
end

return DataController