local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage:FindFirstChild("Assets")
local Packages = ReplicatedStorage:FindFirstChild("Packages")

local Knit = require(Packages.Knit)
local Promise = require(Packages.Promise)

local rarities = {
    {Name = "Common", Weight = 0.50},
    {Name = "Uncommon", Weight = 0.30},
    {Name = "Rare", Weight = 0.15},
    {Name = "Legendary", Weight = 0.04},
    {Name = "Mythical", Weight = 0.01},
}

local SummonService = Knit.CreateService {
    Name = "SummonService",
    Client = {
        ShuffleTime = Knit.CreateSignal(),
    },
}

function SummonService:UpdateShuffle()
    task.spawn(function()
        while true do
            if tick() - self.LastShuffleTime > self.ShuffleCooldown then
                self:ShuffleCurrentTowers()
                
                self.LastShuffleTime = tick()
                print("Towers shuffled at: ", os.date("%Y-%m-%d %H:%M:%S"))
            end
            self.Client.ShuffleTime:FireAll(math.floor(self.ShuffleCooldown - (tick() - self.LastShuffleTime)))
            task.wait(1)
            --aa
        end
    end)
end

function SummonService:ShuffleCurrentTowers()
    local categorizedTowers = {}
    print("yo")
--a
    for _, towerModule in pairs(Assets.Towers:GetChildren()) do
        print("Looped")
        if towerModule:IsA("ModuleScript") then
            print(`Loading tower module: {towerModule.Name}`)
            local tower = require(towerModule)
            local rarity = tower.Rarity

            if not categorizedTowers[rarity] then
                categorizedTowers[rarity] = {}
            end

            table.insert(categorizedTowers[rarity], tower)
        end
    end

    local selectedTowers = {}
    print("Categorized Towers: ", categorizedTowers)
    for _, rarityData in ipairs(rarities) do
        local rarityName = rarityData.Name
        local towersOfRarity = categorizedTowers[rarityName]

        if towersOfRarity and #towersOfRarity > 0 then
            local randomIndex = math.random(1, #towersOfRarity)
            print(`Selected {rarityName} tower: {towersOfRarity[randomIndex].Name}`)
            table.insert(selectedTowers, towersOfRarity[randomIndex])
        end
    end

    self.CurrentTowers = selectedTowers
    print(self.CurrentTowers)
end

function SummonService.Client:GetCurrentTowers()
    return SummonService.CurrentTowers
end

function SummonService.Client:Summon(Player: Player, Amount)
    local results = {}

    for i = 1, Amount do
        local totalWeight = 0
        for _, rarity in ipairs(rarities) do
            totalWeight += rarity.Weight
        end

        local roll = math.random()
        local cumulative = 0
        local selectedRarity = nil

        for _, rarity in ipairs(rarities) do
            cumulative += rarity.Weight
            if roll <= cumulative then
                selectedRarity = rarity.Name
                break
            end
        end

        local possibleTowers = {}
        
        for _, tower in ipairs(SummonService.CurrentTowers) do
            if tower.Rarity == selectedRarity then
                table.insert(possibleTowers, tower)
            end
        end

        if #possibleTowers > 0 then
            --prick
            local picked = possibleTowers[math.random(1, #possibleTowers)]
            table.insert(results, picked)
            local Profile = SummonService.DataService:GetProfile(Player)
            local towers = Profile:Get("Towers")
            if not towers then
                towers = {}
                --what*=
            end
            table.insert(towers, picked.Name)
            Profile:Set("Towers", towers)
            print(Profile:Get("Towers"),"mg")
        else
            warn("No towers available for rarity: " .. selectedRarity)
        end
    end

    table.sort(results, function(a, b)
        local function getRarityIndex(rarityName)
            for i, rarity in ipairs(rarities) do
                if rarity.Name == rarityName then
                    return i
                end
            end
            return math.huge
        end
        return getRarityIndex(a.Rarity) < getRarityIndex(b.Rarity)
    end)

    return Promise.resolve(results)
end

function SummonService:KnitInit()
    self.DataService = Knit.GetService("DataService")

    self.LastShuffleTime = tick()
    self.CurrentTowers = {}
    self.ShuffleCooldown = RunService:IsStudio() and 5 or 30*60

    self:ShuffleCurrentTowers()
    self:UpdateShuffle()
end

return SummonService