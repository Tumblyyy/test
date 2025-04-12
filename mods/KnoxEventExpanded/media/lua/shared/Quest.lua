lua
-- Quest.lua

local Quest = {}
local Objective = {}

-- Quest class
function Quest:new(questID, title, description, objectives, rewards, prerequisites, isRepeatable, relationshipPrerequisite, faction)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.questID = questID
    o.title = title
    o.description = description
    o.objectives = objectives or {}
    o.rewards = rewards or {}
    o.prerequisites = prerequisites or {}
    o.relationshipPrerequisite = relationshipPrerequisite
    o.faction = faction
    o.isRepeatable = isRepeatable or false
    return o
end

function Quest:checkCompletion(player)
    for i, objective in ipairs(self.objectives) do
        if not objective.isCompleted then
            return false
        end
    end
    return true
end

function Quest:giveRewards(player)
    for i, reward in ipairs(self.rewards) do
        local itemType = reward[1]
        local quantity = reward[2]
        player:getInventory():AddItem(itemType, quantity)
    end
end

function Quest:onStart(player, npc)
    -- Stub method
    for i, objective in ipairs(self.objectives) do
        if objective.onStart then
            objective:onStart(player, npc)
        end
    end

end

function Quest:onFinish(player, npc, questGiver)
    <CODE_BLOCK>
    if questGiver and self.faction then
        QuestEvents.changeRelationship(player:getOnlineID(), self.faction, 10) -- Assuming faction affects relationship
    end
    </CODE_BLOCK>
end

-- CraftObjective class
local CraftObjective = {}
setmetatable(CraftObjective, { __index = Objective })

function CraftObjective:new(itemToCraft, quantity)
    local o = Objective:new("craft", itemToCraft, quantity)
    setmetatable(o, self)
    self.__index = self
    o.itemToCraft = itemToCraft
    o.quantity = quantity
    return o
end

-- BuildObjective class
local BuildObjective = {}
setmetatable(BuildObjective, { __index = Objective })

function BuildObjective:new(buildingType, quantity)
    local o = Objective:new("build", buildingType, quantity)
    setmetatable(o, self)
    self.__index = self
    o.buildingType = buildingType
    o.quantity = quantity
    return o
end

-- ClearAreaObjective class
local ClearAreaObjective = {}
setmetatable(ClearAreaObjective, { __index = Objective })

function ClearAreaObjective:new(areaBounds, targetType, quantity)
    local o = Objective:new("clearArea", targetType, quantity)
    setmetatable(o, self)
    self.__index = self
    o.areaBounds = areaBounds
    o.targetType = targetType
    o.quantity = quantity
    return o
end

function Quest.getAvailableQuests(faction)
    local availableQuests = {}
    for _, quest in pairs(quests) do
        if quest.faction == faction then
            table.insert(availableQuests, quest)
        end
    end
    return availableQuests
end



-- Objective class
function Objective:new(objectiveType, target, quantity)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.objectiveType = objectiveType
    o.target = target
    o.quantity = quantity
    o.isCompleted = false
    o.timeLimit = nil
    o.startTime = nil
    return o
end

function Objective:checkProgress(player)
    -- Stub method
end

function Objective:onStart(player, npc)
    self.startTime = os.time()
end

function Objective:checkCompletion(player)
    if self.timeLimit then
        local elapsedTime = os.time() - self.startTime
        if elapsedTime >= self.timeLimit then
            self.isCompleted = false
            return false
        end
    end
end

function Objective:onComplete(player, npc)
    -- Stub method
end

function CraftObjective:checkProgress(player)
    if self.objectiveType == "craft" then
        local count = 0
        for i=0, player:getInventory():getItems():size()-1 do
            local item = player:getInventory():getItems():get(i)
            if item:getFullType() == self.itemToCraft then
                count = count + item:getCount()
            end
        end
        if count >= self.quantity then
            self.isCompleted = true
        end
    end
end

function BuildObjective:checkProgress(player)
    if self.objectiveType == "build" then
        -- Check if the player has built the required building
        -- This will likely require accessing the player's known construction or building data
        -- For now, we'll just print a message and assume it's completed
        print("BuildObjective:checkProgress - Building built: " .. self.buildingType .. ", Quantity: " .. self.quantity)
        -- In a real implementation, you would check the actual building state
        -- and update self.isCompleted accordingly.
        -- For this example, we'll just mark it as completed immediately.
        self.isCompleted = true 
    end
end

function ClearAreaObjective:checkProgress(player)
    if self.objectiveType == "clearArea" then
        -- Check if the entity was killed inside the area bounds
        -- You'll need to get the position of the killed entity and check if it's within self.areaBounds
        -- This will likely involve using some game-specific functions to get entity positions and do the bounds check
        -- For now, we'll just print a message and assume it's completed
        print("ClearAreaObjective:checkProgress - Area cleared: " .. self.targetType .. ", Quantity: " .. self.quantity)
        -- In a real implementation, you would check the actual kills within the area
        -- and update self.isCompleted accordingly.
        -- For this example, we'll just mark it as completed immediately.
        self.isCompleted = true
    end
end


-- Global quests table
local quests = {}

-- Define interact quest
local interactObjective = Objective:new("interact", "Chair", 1)
function interactObjective:checkProgress(player)
    if self.objectiveType == "interact" then
        -- The progress is handled in QuestEvents.lua
    end
end
local interactQuest = Quest:new("interact", "Interact with a chair", "Interact with a chair.", {interactObjective}, {{"Money", 1}}, {}, false, nil, nil)
quests[interactQuest.questID] = interactQuest

-- Define fetchBandages quest
local fetchBandagesObjective = Objective:new("fetch", "Bandage", 5)
function fetchBandagesObjective:checkProgress(player)
    if self.objectiveType == "fetch" then
        local count = 0
        for i=0, player:getInventory():getItems():size()-1 do
            local item = player:getInventory():getItems():get(i)
            if item:getType() == self.target then
                count = count + 1
            end
        end

        if count >= self.quantity then
            self.isCompleted = true
        end
    end
end

local fetchBandagesQuest = Quest:new("fetchBandages", "Fetch Bandages", "Bring me 5 bandages.", {fetchBandagesObjective}, {{"Bandage", 5}, {"Money", 10}}, {}, false, nil, "Survivors")
quests[fetchBandagesQuest.questID] = fetchBandagesQuest

-- Define kill quest
local killObjective = Objective:new("kill", "Zombie", 10)
function killObjective:checkProgress(player)
    if self.objectiveType == "kill" then
        -- The progress is handled in QuestEvents.lua
    end
end
local killQuest = Quest:new("kill", "Kill Zombies", "Kill 10 zombies.", {killObjective}, {{"BaseballBat", 1}}, {}, false, nil, "Bandits")
quests[killQuest.questID] = killQuest

-- Define raid quest
local raidObjective = Objective:new("reach", "Building", 1)
function raidObjective:checkProgress(player)
    if self.objectiveType == "reach" then
        -- The progress is handled in QuestEvents.lua
    end
end
local raidQuest = Quest:new("raid", "Raid a building", "Raid the nearest building.", {raidObjective}, {{"HuntingRifle", 1}}, {}, false, nil, "Police")
quests[raidQuest.questID] = raidQuest

-- Define escort quest
local escortObjective = Objective:new("escort", "SurvivorNpc", 1)
function escortObjective:checkProgress(player)
    if self.objectiveType == "escort" then
        -- The progress is handled in QuestEvents.lua
    end
end
local escortQuest = Quest:new("escort", "Escort", "Escort me to the safehouse.", {escortObjective}, {{"Katana", 1}}, {}, false, nil, "Soldiers")
quests[escortQuest.questID] = escortQuest

-- Define talk quest
local talkObjective = Objective:new("talk", "SurvivorNpc", 1)
function talkObjective:checkProgress(player)
    if self.objectiveType == "talk" then
        -- The progress is handled in QuestEvents.lua
    end
end
local talkQuest = Quest:new("talk", "Talk", "Talk to me.", {talkObjective}, {{"Money", 1}}, {}, false, nil, nil)
quests[talkQuest.questID] = talkQuest


return {
  Quest = Quest,
  Objective = Objective,
  CraftObjective = CraftObjective,
  ClearAreaObjective = ClearAreaObjective,
  quests = quests,
}