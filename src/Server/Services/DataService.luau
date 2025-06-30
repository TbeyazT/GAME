--[[
    File Purpose:
]]

-------------------------- Roblox Services --------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local BadgeService = game:GetService("BadgeService")

local Assets = ReplicatedStorage:FindFirstChild("Assets")

-------------------------- Knit --------------------------
local Knit = require(ReplicatedStorage.Packages.Knit)

-------------------------- Util --------------------------
local Dumpster = require(ReplicatedStorage.Packages.Dumpster)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

-------------------------- Modules --------------------------
local ProfileStore = require(script.Parent.Parent.ProfileStore)
local DataTemplate = {
	TimeSpent = 0,
	Coins = 100,
	Towers = {},
}
local ReplicaService = require(ServerScriptService:FindFirstChild("ReplicaService"))
-------------------------- Dependencies --------------------------
-------------------------- Constants --------------------------
local STORE_NAME: string = "LIVE"
local STORE_VERSION: number = 1

if RunService:IsStudio() then
    STORE_NAME = "STUDIO"
end

STORE_NAME = `{STORE_NAME}_{string.format("%03d", STORE_VERSION)}`

-------------------------- Fields --------------------------
local PlayerStore = ProfileStore.New(STORE_NAME, DataTemplate)

if RunService:IsStudio() and (ServerStorage:GetAttribute("MOCK_DATA_STORE") == true) then
    warn("Using mock data store")
    PlayerStore = PlayerStore.Mock
end

local DataService = Knit.CreateService {
    Loaded = Signal.new(),
    Released = Signal.new(),

    Name = "DataService",
    Client = {},

    _profiles = {} :: {[Player]: typeof(PlayerStore:StartSessionAsync())},
    _replicas = {},
    _changedEvents = {},
    _loadedPlayers = {} :: {Player},
}

-------------------------- Local Functions --------------------------

-------------------------- Lifetime Methods --------------------------
function DataService:KnitStart()
    self.Loaded:Connect(function(player: Player)
        table.insert(self._loadedPlayers, player)
    end)

    for _, player: Player in Players:GetPlayers() do
        task.spawn(function()
            self:_playerAdded(player)
        end)
    end

    Players.PlayerAdded:Connect(function(player: Player)
        self:_playerAdded(player)
    end)
end

-------------------------- Public Functions --------------------------
-- Returns the value retrieved from a players data:
function DataService:Get(player: Player, key: string): any?
    return self:_getKey(player, key)
end

function DataService:Set(player: Player, key: string, value: any?): "Promise"
    return self:_setKey(player, key, value)
end

function DataService:GetProfile(player: Player)
    return self:_getProfile(player)
end

function DataService:SaveAsync(player: Player)
    local profile = self:_getProfile(player)

    if not profile then
        return
    end

    profile:Save()
end

function DataService:IsProfileActive(player: Player): boolean
    local profile = self:_getProfile(player)

    if not profile then
        return false
    end
    
    return profile:IsActive()
end

function DataService:OnChanged(player: Player, key: string, callback)
    return self:_getKeyChangedSignal(player, key):Connect(callback)
end

-- Iterates through existing players, and listens to players being loaded
-- Returns a signal connection
function DataService:ObservePlayerAdded(callback: (player: Player) -> ()): RBXScriptSignal
    assert(typeof(callback) == "function", "Callback must be a function type")

    for _, player: Player in self:GetLoadedPlayers() do
        task.spawn(callback, player)
    end

    return self.Loaded:Connect(callback)
end

-- Returns an array of players whos data has been loaded into the game
function DataService:GetLoadedPlayers(): {Player?}
    return self._loadedPlayers
end
-------------------------- Client Functions --------------------------
function DataService.Client:AmILoadedYet(player: Player): boolean
    local profile = self.Server:_getProfile(player)

    if not profile then
        return false
    end

    return profile:IsActive()
end
-------------------------- Private Functions --------------------------
function DataService:_playerAdded(player: Player): ()
    local profile = PlayerStore:StartSessionAsync(`Player_{player.UserId}`, {
        Cancel = function()
            return not player:IsDescendantOf(Players)
        end
    })

    if not BadgeService:UserHasBadgeAsync(player.UserId, 751095141305875) then
        BadgeService:AwardBadge(player.UserId, 751095141305875)
    end

    if not profile then
        -- Some Roblox DataStores error
        -- Another server could have been trying to load the profile at the same time as well...
        player:Kick("Failed to load you data. Please rejoin soon!")
        return
    end
    
    profile:AddUserId(player.UserId) -- GDPR Compliance
    profile:Reconcile() -- Fills in missing variables from DataTemplate
    
    profile.OnSessionEnd:Connect(function()
        self._profiles[player] = nil
        self.Released:Fire(player)

        player:Kick("Profile seesion end - Please rejoin!")
    end)

    profile:MessageHandler(function(message, processed)
        print("Message received:", message)
        processed()
    end)

    if not player:IsDescendantOf(Players) then
        -- Player left before the profile was loaded
        profile:EndSession()
        return
    end

    -- The profile has been successfully loaded
    self:_setupReplica(player, profile)
    player:SetAttribute("DATA_LOADED", true)
    self.Loaded:Fire(player)
end

function DataService:_getProfile(player: Player): ()
    if not player then
        return
    end

    return self._profiles[player]
end

function DataService:_getKey(player: Player, key: string): any?
    local playerProfile = self:_getProfile(player)

    if not playerProfile then
        return
    end

    local value = shared.Get(playerProfile.Data, key)

    if value and typeof(value) == "table" then
        value = TableUtil.Copy(value, true)
    end

    return value
end

function DataService:_setKey(player: Player, key: string, new_value: any): "Promise"
    return Promise.new(function(resolve, reject)
        if not (self._replicas[player] and self._profiles[player]) then
            return reject(`No profile found for: {player}`)
        end

        local succ, err = pcall(function()
            self._replicas[player]:SetValue(key, new_value)
        end)

        if not succ then
            return reject(`Failed to set key: {key} for player: {player}\nReason: {err}`)
        end

        local old_value: any? = self:_getKey(player, key)
        local changedSignal: "Signal" = self:_getKeyChangedSignal(player, key)
        
        changedSignal:Fire(new_value, old_value)
        resolve()
    end)
end

-- Sets up the data replica for the player
function DataService:_setupReplica(player: Player, profile): ()
    local dumpster = Dumpster.new()
    self._profiles[player] = profile

    local replicaClassToken = ReplicaService.NewClassToken(tostring(player.UserId))

    self._replicas[player] = ReplicaService.NewReplica({
        ClassToken = replicaClassToken,
        Replication = "All",
        Data = profile.Data or {}
    })

    -- Create initial key changed signals
    for key: string, _: any in (profile.Data or {}) do
        if not self._changedEvents[player] then
            self._changedEvents[player] = {}
        end

        if not self._changedEvents[player][key] then
            self._changedEvents[player][key] = Signal.new()
        end
    end

    -- cleanup method:
    dumpster:Add(function(): ()
        local foundAt = table.find(self._loadedPlayers, player)

        if foundAt then
            table.remove(self._loadedPlayers, foundAt)
            foundAt = nil
        end

        if self._replicas[player] then
            self._replicas[player]:Destroy()
            self._replicas[player] = nil
        end

        -- Remove all changed event signals for this player
        if self._changedEvents[player] then
            for _, keyChangedSignal in self._changedEvents[player] do
                keyChangedSignal:Destroy()
            end

            table.clear(self._changedEvents[player])
            self._changedEvents[player] = nil
        end

        player = nil
        dumpster = nil

        profile:EndSession()
        profile = nil
    end)

    -- Dumpster will destroy if the player is no longer in the game or when they leave
    dumpster:AttachTo(player)
end

function DataService:_getKeyChangedSignal(player: Player, signalName: string): "Signal"
    if not self._changedEvents[player] then
        self._changedEvents[player] = {}
    end
    
    if not self._changedEvents[player][signalName] then
        self._changedEvents[player][signalName] = Signal.new()
    end

    return self._changedEvents[player][signalName]
end

return DataService