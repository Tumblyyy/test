-- Quest Events for Knox Event Expanded
-- Handles events that can trigger quest progress updates

require "04_QuestSystem/QuestManager"

local QuestEvents = {}

-- Helper function to get quests with kill objectives
local function getQuestsWithKillObjectives(playerId)
    local questsWithKillObjectives = {}
    local activeQuests = QuestManager.getAllActiveQuests(playerId)
    if not activeQuests then return questsWithKillObjectives end

    for questId, _ in pairs(activeQuests) do
        local questDef = QuestManager.getQuest(questId)
        if questDef and questDef.objectives then
            for _, objective in ipairs(questDef.objectives) do
                if objective.type == "kill" then
                    table.insert(questsWithKillObjectives, questId)
                    break
                end
            end
        end
    end

    return questsWithKillObjectives
end

-- Track killed characters (renamed from onNPCDeath for clarity)
local function onCharacterDeath(npc)
    if not npc or not npc:getModData() then return end

    local npcType = npc:getModData().type
    if not npcType then return end
    
    local player = getSpecificPlayer(0)
    local playerId = player:getPlayerNum()
    
    -- Check active quests with kill objectives
    local quests = getQuestsWithKillObjectives(playerId)
    if not quests then return end
    
    for _, questId in ipairs(quests) do
        local questInstance = QuestManager.getActiveQuest(playerId, questId)
        if questInstance and questInstance.objectives then
            local questDef = QuestManager.getQuest(questId)
            -- Go through each objective
            for i, objective in ipairs(questInstance.objectives) do
                local objDef = questDef.objectives[i]
                -- If the objective is already completed, skip it
                if objective.completed then goto continue end
                -- Check if this is a kill objective matching the NPC type
                if objDef.type == "kill" and objDef.targetType == npcType then
                    QuestManager.updateObjective(playerId, questId, objDef.id, 1)
                end
                ::continue::
            end
        end
    end
end

-- Helper function to get quests with item objectives for a specific item type
local function getQuestsWithItemObjectives(playerId, itemType)
    local questsWithItemObjectives = {}
    local activeQuests = QuestManager.getAllActiveQuests(playerId)
    if not activeQuests then return questsWithItemObjectives end
    
    for questId, _ in pairs(activeQuests) do
        local questDef = QuestManager.getQuest(questId)
        if questDef and questDef.objectives then
            for _, objective in ipairs(questDef.objectives) do
                if objective.type == "item" and objective.items and table.contains(objective.items, itemType) then
                    table.insert(questsWithItemObjectives, questId)
                    break
                end
            end
        end
    end
    
    return questsWithItemObjectives
end

-- Helper function to get quests with location objectives
local function getQuestsWithLocationObjectives(playerId)
    local questsWithLocationObjectives = {}
    local activeQuests = QuestManager.getAllActiveQuests(playerId)
    if not activeQuests then return questsWithLocationObjectives end
    
    for questId, _ in pairs(activeQuests) do
        local questDef = QuestManager.getQuest(questId)
        if questDef and questDef.objectives then
            for _, objective in ipairs(questDef.objectives) do
                if objective.type == "location" then
                    table.insert(questsWithLocationObjectives, questId)
                    break
                end
            end
        end
    end
    
    return questsWithLocationObjectives
end





-- Check if a player is near a location
local function isPlayerNearLocation(playerId, x, y, z)
    local player = getSpecificPlayer(playerId)
    if not player then return false end

    local playerX = player:getX()
    local playerY = player:getY()
    local playerZ = player:getZ()

    -- Check if the player is within a 5-tile radius (squared distance for efficiency)
    local distanceSq = (playerX - x) * (playerX - x) + (playerY - y) * (playerY - y)

    return distanceSq <= 25 and playerZ == z
end

local function onLocationEnter(playerId, x, y, z)
    local quests = getQuestsWithLocationObjectives(playerId)
    if not quests then return end
    
    for _, questId in ipairs(quests) do
        local questInstance = QuestManager.getActiveQuest(playerId, questId)
        if not questInstance or not questInstance.objectives then goto continue end
        local questDef = QuestManager.getQuest(questId)
        for i, objective in ipairs(questInstance.objectives) do
            local objDef = questDef.objectives[i]
            if not objective.completed and objDef.type == "location" and isPlayerNearLocation(playerId, x, y, z) then
                QuestManager.updateObjective(playerId, questId, objDef.id, 1)
            end
        end
        ::continue::
    end
end

-- Track item pickups
local function onItemPickup(player, item)
    if not player or not item then return end
    
    local playerId = player:getPlayerNum()
    local inventory = player:getInventory()
    
    -- Check active quests with item objectives for this item
    local quests = getQuestsWithItemObjectives(playerId, item:getFullType())
    if not quests then return end
    
    for _, questId in ipairs(quests) do
        local questInstance = QuestManager.getActiveQuest(playerId, questId)
        if not questInstance or not questInstance.objectives then goto continue end
        local questDef = QuestManager.getQuest(questId)
        if not questDef or not questDef.objectives then goto continue end
        for i, objective in ipairs(questInstance.objectives) do
            -- Count matching items in inventory
            local itemCount = 0
            if objective.completed then goto continue end
            local objDef = questDef.objectives[i]
                local objDef = questDef.objectives[i]
                if not objective.completed and objDef.type == "location" and isPlayerNearLocation(playerId, x, y, z) then
                    QuestManager.updateObjective(playerId, questId, objDef.id, 1)
                end
            end
        end
    end
end
-- Track item pickups
local function onItemPickup(player, item)
    if not player or not item then return end
    
    local playerId = player:getPlayerNum()
    
    -- Check active quests with item objectives for this item
    local quests = getQuestsWithItemObjectives(playerId, item:getFullType())
    if not quests then return end
    
    for _, questId in ipairs(quests) do
        local questInstance = QuestManager.getActiveQuest(playerId, questId)
        local questDef = QuestManager.getQuest(questId)
        if not questDef or not questDef.objectives then return end
        for i, objective in ipairs(questInstance.objectives) do
            local objDef = questDef.objectives[i]
            if not objective.completed and objDef.type == "item" and objDef.items and table.contains(objDef.items, item:getFullType()) then
                QuestManager.updateObjective(playerId, questId, objDef.id, 1)
            end
        end
    end
end

-- Track escort objectives (NPC reached destination)
local escortedNpcs = {}

local function onNPCReachedDestination(npcId, targetLocation)
    if not npcId or not targetLocation then return end
    
    local player = getSpecificPlayer(0)
    local playerId = player:getPlayerNum()
    
    -- Check all active quests for escort objectives
    local activeQuests = QuestManager.getAllActiveQuests(playerId)
    if not activeQuests then return end
    
    for questId, questInstance in pairs(activeQuests) do
        local questDef = QuestManager.getQuest(questId)
        if questDef and questDef.objectives then
            -- Go through each objective
            for i, objective in ipairs(questInstance.objectives) do
                local objDef = questDef.objectives[i]
                -- Check if this is an escort objective matching the NPC
                if objDef.type == "escort" and objDef.targetId == npcId then
                    QuestManager.updateObjective(playerId, questId, objDef.id, 1)
                end
            end
        end
    end
end

-- Register an NPC to be escorted
local function registerEscortedNpc(npcId, targetLocation)
    print("registerEscortedNpc called")
    print(debug.traceback())
end

-- Track protection objectives (NPC survived)
local function onNPCSurvivalCheck(npcId, duration)
    if not npcId or not duration then return end
    
    local player = getSpecificPlayer(0)
    local playerId = player:getPlayerNum()
    
    -- Check all active quests for protection objectives
    local activeQuests = QuestManager.getAllActiveQuests(playerId)
    if not activeQuests then return end
    
    for questId, questInstance in pairs(activeQuests) do
        local questDef = QuestManager.getQuest(questId)
        if questDef and questDef.objectives then
            -- Go through each objective
            for i, objective in ipairs(questInstance.objectives) do
                local objDef = questDef.objectives[i]
                -- Check if this is a protection objective matching the NPC
                if objDef.type == "protect" and 
                   (not objDef.targetId or objDef.targetId == npcId) and
                   (not objDef.duration or duration >= objDef.duration) then
                    QuestManager.updateObjective(playerId, questId, objDef.id, 1)
                end
            end
        end
    end
end

-- Register an NPC to be protected
local function registerProtectedNpc(npcId, duration)
    print("registerProtectedNpc called") -- Add this line
    protectedNpcs[npcId] = { duration = duration }
end

-- Register event handlers

-- Handle server command responses
local function onServerCommand(module, command, args)
    if module ~= "QuestSystem" then return end
    
    if command == "QuestStarted" then
        -- Show notification
        player:Say("New quest started: " .. args.questTitle)
    elseif command == "QuestCompleted" then
        -- Show notification
        player:Say("Quest completed: " .. args.questTitle)
    elseif command == "ObjectiveUpdated" then
        -- Show notification
        player:Say("Objective updated: " .. args.objectiveDescription)
   end
end

Events.OnServerCommand.Add(onServerCommand)

QuestEvents.OnLocationEnter = onLocationEnter

Events.OnCharacterDead.Add(onCharacterDeath)
Events.OnItemPickup.Add(onItemPickup)
QuestEvents.OnNPCReachedDestination = onNPCReachedDestination
QuestEvents.OnNPCSurvivalCheck = onNPCSurvivalCheck
QuestEvents.registerEscortedNpc = registerEscortedNpc
QuestEvents.registerProtectedNpc = registerProtectedNpc
return QuestEvents 