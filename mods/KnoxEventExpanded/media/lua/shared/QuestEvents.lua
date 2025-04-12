lua
-- QuestEvents.lua

local QuestEvents = {}

-- questDatabase global table to store all the quests assigned to players
QuestEvents.questDatabase = {}

-- relationshipDatabase global table to store relationship values
QuestEvents.relationshipDatabase = {}

-- playerGroups global table to store recruited NPCs for each player
QuestEvents.playerGroups = {}

-- registerQuestToPlayer function to add a quest to a player
function QuestEvents.registerQuestToPlayer(player, questID)
    local playerID = player:getOnlineID()
    if not QuestEvents.questDatabase[playerID] then
        QuestEvents.questDatabase[playerID] = {}
    end
    QuestEvents.questDatabase[playerID][questID] = true
end

-- Event handler for OnInventoryItemAdded
Events.OnInventoryItemAdded.Add(function(player, item)
  -- Check all the active quests of the player
  local playerID = player:getOnlineID()
  if QuestEvents.questDatabase[playerID] then
      for questID, _ in pairs(QuestEvents.questDatabase[playerID]) do
          local quest = quests[questID];
          if quest then
            for i, objective in ipairs(quest.objectives) do
                if objective.objectiveType == "fetch" and objective.target == item:getType() then
                  objective:checkProgress(player)
                end
            end
          end
      end
  end
end)

-- Event handler for OnZombieKilled
Events.OnZombieKilled.Add(function(player, zombie)
    local playerID = player:getOnlineID()
    if QuestEvents.questDatabase[playerID] then
        for questID, _ in pairs(QuestEvents.questDatabase[playerID]) do
            local quest = quests[questID];
            if quest then
                for i, objective in ipairs(quest.objectives) do
                    if objective.objectiveType == "kill" and objective.target == "Zombie" and not objective.isCompleted then -- Keep the original kill objective
                        objective:checkProgress(player, zombie)
                    elseif objective.objectiveType == "clearArea" and objective.targetType == "Zombie" and not objective.isCompleted then -- Check for ClearAreaObjective
                        objective:checkProgress(player, zombie)
                    end
                end
            end
        end
    end
end)

-- Event handler for OnPlayerMove
Events.OnPlayerMove.Add(function(player, square)
    local playerID = player:getOnlineID()
    if QuestEvents.questDatabase[playerID] then
        for questID, _ in pairs(QuestEvents.questDatabase[playerID]) do
            local quest = quests[questID];
            if quest then
                for i, objective in ipairs(quest.objectives) do
                    if objective.objectiveType == "reach" and objective.target == "Building" and not objective.isCompleted then
                        objective:checkProgress(player)
                    end
                end
            end
        end
    end
end)

-- Event handler for OnNpcTalk
Events.OnNpcTalk.Add(function(player, npc)
    local playerID = getPlayerId(player)
    local npcPreset = npc:getNpcPreset()
    if npcPreset and npcPreset.partyID then
        QuestEvents.changeRelationship(playerID, npcPreset.partyID, 5)
    end

    -- Check if the player has any quests related to this NPC and update the progress.
    if QuestEvents.questDatabase[playerID] then
        for questID, _ in pairs(QuestEvents.questDatabase[playerID]) do
            local quest = quests[questID]
            if quest then
                for _, objective in ipairs(quest.objectives) do
                    if objective.objectiveType == "talk" and objective.target == npc:getId() and not objective.isCompleted then
                        objective:checkProgress(player)
                    end
                end
                if quest:checkCompletion(player) then
                    quest:onFinish(player, npc)
                end
            end
        end
    end
end)

-- Event handler for OnItemCrafted
Events.OnItemCrafted.Add(function(player, item)
    local playerID = player:getOnlineID()
    if QuestEvents.questDatabase[playerID] then
        for questID, _ in pairs(QuestEvents.questDatabase[playerID]) do
            local quest = quests[questID];
            if quest then
                for i, objective in ipairs(quest.objectives) do
                    if objective.objectiveType == "craft" and objective.target == item:getFullType() and not objective.isCompleted then
                        objective:checkProgress(player, item)
                    end
                end
            end
        end
    end
end)

-- Event handler for OnPlayerUpdate
Events.OnPlayerUpdate.Add(function(player)
    local playerID = player:getOnlineID()
    if QuestEvents.questDatabase[playerID] then
        for questID, _ in pairs(QuestEvents.questDatabase[playerID]) do
            local quest = quests[questID];
            if quest then
                for i, objective in ipairs(quest.objectives) do
                    if objective.objectiveType == "build" and not objective.isCompleted then
                        local buildings = player:getCurrentSquare():getBuilding()
                        if buildings then
                            objective:checkProgress(player, buildings)
                        end
                    end
                end
            end
        end
    end
end)

-- Event handler for OnPlayerInteract
Events.OnPlayerInteract.Add(function(player, object)
    local playerID = player:getOnlineID()
    if QuestEvents.questDatabase[playerID] then
        for questID, _ in pairs(QuestEvents.questDatabase[playerID]) do
            local quest = quests[questID];
            if quest then
                for i, objective in ipairs(quest.objectives) do
                    if objective.objectiveType == "talk" and objective.target == "SurvivorNpc" and not objective.isCompleted then
                        objective:checkProgress(player)
                    end
                end
            end
        end
    end
end)

-- Event handler for OnGameTimeChanged
Events.OnGameTimeChanged.Add(function()
    for playerID, quests in pairs(QuestEvents.questDatabase) do
        for questID, _ in pairs(quests) do
            local quest = quests[questID]
            if quest then
                for i, objective in ipairs(quest.objectives) do
                    objective:checkCompletion()
                end
            end
        end
    end
end)

-- Function to get the relationship value between a player and a party
function QuestEvents.getRelationship(playerID, partyID)
    if string.find(partyID, "Faction_") then
        -- Global relationship for factions
        return QuestEvents.relationshipDatabase[partyID] or 0
    else
        -- Local relationship for NPCs
        if not QuestEvents.relationshipDatabase[playerID] then
            return 0
        end
        return QuestEvents.relationshipDatabase[playerID][partyID] or 0
    end
end

-- Function to set the relationship value
function QuestEvents.setRelationship(playerID, partyID, value)
    if string.find(partyID, "Faction_") then
        -- Global relationship for factions
        QuestEvents.relationshipDatabase[partyID] = value
    else
        -- Local relationship for NPCs
        if not QuestEvents.relationshipDatabase[playerID] then
            QuestEvents.relationshipDatabase[playerID] = {}
        end
        QuestEvents.relationshipDatabase[playerID][partyID] = value
    end
end

-- Function to increase or decrease the relationship value
function QuestEvents.changeRelationship(playerID, partyID, change)
    local currentRelationship = QuestEvents.getRelationship(playerID, partyID)
    QuestEvents.setRelationship(playerID, partyID, currentRelationship + change)
end

-- Function to get the relationship state (Hostile, Neutral, Allied)
function QuestEvents.getRelationshipState(playerID, partyID)
    local relationship = QuestEvents.getRelationship(playerID, partyID)
    if relationship <= -25 then
        return "Hostile"
    elseif relationship >= 25 then
        return "Allied"
    else
        return "Neutral"
    end
end

-- Function to check if the player is an ally of the party
function QuestEvents.isAlly(playerID, partyID)
    return QuestEvents.getRelationshipState(playerID, partyID) == "Allied"
end

-- Function to check if the player is hostile to the party
function QuestEvents.isHostile(playerID, partyID)
    return QuestEvents.getRelationshipState(playerID, partyID) == "Hostile"
end

-- Helper function to get player ID, works for both PlayerCharacter and ISBaseCharacter
local function getPlayerId(player)
    if player.getOnlineID then
        -- For PlayerCharacter
        return player:getOnlineID()
    elseif player.getDescriptor then
        -- For ISBaseCharacter (NPCs)
        return player:getDescriptor():getCharacterID()
    else
        return nil
    end
end


-- Event handler for OnPlayerAttack
Events.OnPlayerAttack.Add(function(player, target)
    local playerID = getPlayerId(player)
    local targetCharacter = target:getCharacter()
    if targetCharacter then
        local npcPreset = targetCharacter:getNpcPreset()
        if npcPreset and npcPreset.partyID then
            QuestEvents.changeRelationship(playerID, npcPreset.partyID, -10)
        end
    end
end)

-- Function to check if a quest can be assigned based on relationship
function QuestEvents.canAssignQuest(playerID, npc)
    local npcPreset = npc:getNpcPreset()
    if not npcPreset or not npcPreset.partyID then
        return false -- NPC has no faction or party
    end
    local relationship = QuestEvents.getRelationship(playerID, npcPreset.partyID)
    if relationship <= -50 then
        return false -- Very hostile relationship, no quest
    elseif relationship >= 50 then
        return true -- Good relationship, quest can be assigned
    else
        -- Neutral relationship, 50% chance
        local chance = math.random(1, 100)
        return chance <= 50
    end
end

-- Function to assign a quest to a player based on NPC faction
function QuestEvents.assignQuestByNpc(player, npc)
    local playerID = player:getOnlineID()
    local npcPreset = npc:getNpcPreset()
    if not npcPreset or not npcPreset.faction then
        return false -- NPC has no faction
    end

    local availableQuests = Quest.getAvailableQuests(npcPreset.faction)
    if #availableQuests == 0 then
        return false -- No quests available for this faction
    end

    -- Choose a random quest from the list
    local questIndex = math.random(1, #availableQuests)
    local questID = availableQuests[questIndex].id

    -- Register the quest to the player
    return QuestEvents.registerQuestToPlayer(player, questID)
end

-- Function to decrease relationship
function QuestEvents.degradeRelationship(playerID, partyID, amount)
    local currentRelationship = QuestEvents.getRelationship(playerID, partyID)
    QuestEvents.setRelationship(playerID, partyID, currentRelationship - amount)
end

-- Function to check and degrade all relationships
function QuestEvents.checkRelationshipDegradation()
    for playerID, relationships in pairs(QuestEvents.relationshipDatabase) do
        if type(relationships) == "table" then
            for partyID, _ in pairs(relationships) do
                local amount = math.random(1, 5)
                QuestEvents.degradeRelationship(playerID, partyID, amount)
            end
        else
            -- Degrade global faction relationships
            local amount = math.random(1, 5)
            QuestEvents.degradeRelationship(nil, playerID, amount) -- Use nil for playerID in faction relationships
        end
    end
end

-- Event handler for OnGameDayChanged
Events.OnGameDayChanged.Add(function()
    QuestEvents.checkRelationshipDegradation()
end)

-- Function to add an NPC to a player's group
function QuestEvents.addNpcToPlayerGroup(playerID, npc)
    if not QuestEvents.playerGroups[playerID] then
        QuestEvents.playerGroups[playerID] = {}
    end
    table.insert(QuestEvents.playerGroups[playerID], npc)
end

-- Function to remove an NPC from a player's group
function QuestEvents.removeNpcFromPlayerGroup(playerID, npc)
    if QuestEvents.playerGroups[playerID] then
        for i, member in ipairs(QuestEvents.playerGroups[playerID]) do
            if member == npc then
                table.remove(QuestEvents.playerGroups[playerID], i)
                break
            end
        end
    end
end

-- Function to get a player's group
function QuestEvents.getNpcPlayerGroup(playerID)
    return QuestEvents.playerGroups[playerID] or {}
end

-- Event handler for when a player recruits an NPC
Events.OnNpcRecruited = Events.OnNpcRecruited or Event:new()
Events.OnNpcRecruited.Add(function(player, npc)
    local playerID = getPlayerId(player)
    QuestEvents.addNpcToPlayerGroup(playerID, npc)
end)

-- Event handler for when a player dismisses an NPC
Events.OnNpcDismissed = Events.OnNpcDismissed or Event:new()
Events.OnNpcDismissed.Add(function(player, npc)
    local playerID = getPlayerId(player)
    QuestEvents.removeNpcFromPlayerGroup(playerID, npc)
end)
return QuestEvents