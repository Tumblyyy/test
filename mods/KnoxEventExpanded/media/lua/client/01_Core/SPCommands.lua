if isClient() or isServer()  then return end;

require "00_UI_SP/ISGroupNpcsUI"

-- Not sure where to put this, so let's just put it here
-- Needs to be here since this hook is added quite late in the loading process
Events.OnGameStart.Add(function() Hook.NPCAttack.Add(ISReloadWeaponAction.attackHook); end)

------------------------------------------------------
------------------- DEBUG COMMANDS -------------------
------------------------------------------------------
function testHunger(worldObjects, npc)
    npc:getStats():setHunger(0.8);
end

function testThirst(worldObjects, npc)
    npc:getStats():setThirst(0.8);
end

function testExhaustion(worldObjects, npc)
    npc:getStats():setEndurance(0.3);
end

function toggleNpcBaseDebug(worldObjects, npc)
    local current = npc:getDebugNpcEnable();
    npc:setDebugNpcEnable(not current);
end

function toggleNpcTreeDebug(worldObjects, npc)
    local current = npc:getDebugTreeEnable();
    npc:setDebugTreeEnable(not current);
end

function dumpMemories(worldObjects, npc)
    npc:debugDumpMemories();
end

------------------------------------------------------
-----------------  GROUP SETTINGS   ------------------
------------------------------------------------------
function toggleNpcAggressive()
    local player = getSpecificPlayer(0);
    local group = player:getGroup();
    if group then
        local isGroupAggressive = group:getGroupAggressive();
        if isGroupAggressive then
            -- Will NOT be aggressive after
            getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_Aggressive"));
        else
            -- Will be aggressive after
            getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_Passive"));
        end
        group:toggleAggressive();
    end
end

function toggleNpcRetreat()
    local player = getSpecificPlayer(0);
    local group = player:getGroup();
    if group then
        local isGroupRetreating = group:getGroupRetreat();
        if isGroupRetreating then
            -- Will NOT be retreating after
            getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_Fight"));
        else
            -- Will be retreating after
            getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_Retreat"));
        end
        group:toggleRetreat();
    end
end

function setNpcChopTreesArea(x1, y1, x2, y2)
    local player = getSpecificPlayer(0);
    local group = player:getGroup();
    if group then
        group:setChopTreesArea(x1, y1, x2, y2);
    end
end

function setNpcCorpseClearArea(x1, y1, x2, y2)
    local player = getSpecificPlayer(0);
    local group = player:getGroup();
    if group then
        group:setCorpseClearArea(x1, y1, x2, y2);
    end
end

function setNpcCorpseDumpArea(x1, y1, x2, y2)
    local player = getSpecificPlayer(0);
    local group = player:getGroup();
    if group then
        group:setCorpseDumpArea(x1, y1, x2, y2);
    end
end

function setNpcGuardArea(x1, y1, x2, y2)
    local player = getSpecificPlayer(0);
    local group = player:getGroup();
    if group then
        group:setGuardArea(x1, y1, x2, y2);
    end
end

------------------------------------------------------
------------------ INTERACT COMMANDS------------------
------------------------------------------------------
function driveVehicleNpc(worldObjects, npc, car)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    if car == nil or not instanceof(car, "BaseVehicle") then
        print("Not a valid car");
        return;
    end
    local player = getSpecificPlayer(0);
    print("NPC " ..  tostring(npc:getUsername()) .. " asked to drive");
    local tree = npc:getBehaviorTree();
    local drivingNode = tree:getChildWithName("DrivingSubTree");
    npc:setGoal("DrivingSubTree");
    npc:setSubGoal("");
    drivingNode:setData("DrivingSubTreeVehicle", car);
end

function talkToNpc(worldObjects, npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    local player = getSpecificPlayer(0);
    print("NPC " ..  tostring(npc:getUsername()) .. " asked to speak with");
    local tree = npc:getBehaviorTree();
    local dialogueNode = tree:getChildWithName("DialogueSubTree");
    dialogueNode:setData("DialogueSubTreeIsSpeaking", true);
    dialogueNode:setData("DialogueSubTreeSpeaker", player);
    local playerData = getPlayerData(0);
    playerData.npcDialogueUI.npcObj = npc;
    playerData.npcDialogueUI.npcName = npc:getUsername();
    playerData.npcDialogueUI:setVisible(true);
end

function smallTalkWeather(npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    print("Small talking to Npc " .. tostring(npc:getUsername()) .. " about the weather");
    getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_SpeechSmallTalk"));
    local tree = npc:getBehaviorTree();
    local dialogueNode = tree:getChildWithName("DialogueSubTree");
    dialogueNode:setData("DialogueSubTreeSpeakSubMenu", 1.0);
    dialogueNode:setData("DialogueSubTreeSpeakOption", 1.0);
end

function smallTalkAge(npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    print("Small talking to Npc " .. tostring(npc:getUsername()) .. " about their age");
    getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Npc_Dialogue_SmallTalkAge"));
    local tree = npc:getBehaviorTree();
    local dialogueNode = tree:getChildWithName("DialogueSubTree");
    dialogueNode:setData("DialogueSubTreeSpeakSubMenu", 1.0);
    dialogueNode:setData("DialogueSubTreeSpeakOption", 2.0);
end

function smallTalkOccupation(npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    print("Small talking to Npc " .. tostring(npc:getUsername()) .. " about their occupation");
    getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Npc_Dialogue_SmallTalkOccupation"));
    local tree = npc:getBehaviorTree();
    local dialogueNode = tree:getChildWithName("DialogueSubTree");
    dialogueNode:setData("DialogueSubTreeSpeakSubMenu", 1.0);
    dialogueNode:setData("DialogueSubTreeSpeakOption", 3.0);
end

function askRecentToNpc(npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    print("Asking Npc " .. tostring(npc:getUsername()) .. " about recent events");
    local tree = npc:getBehaviorTree();
    local dialogueNode = tree:getChildWithName("DialogueSubTree");
    dialogueNode:setData("DialogueSubTreeSpeakSubMenu", 0.0);
    dialogueNode:setData("DialogueSubTreeSpeakOption", 2.0);
    --TODO: Update dialogue
    getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_SpeechRecent"));
end

function stopTalkingToNpc(npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    print("Stopped talking to Npc " .. tostring(npc:getUsername()));
    local tree = npc:getBehaviorTree();
    local dialogueNode = tree:getChildWithName("DialogueSubTree");
    dialogueNode:setData("DialogueSubTreeSpeakSubMenu", 0.0);
    dialogueNode:setData("DialogueSubTreeSpeakOption", 4.0);
    getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_SpeechGoodbye"));
end

function askNpcToJoinGroup(npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    local player = getSpecificPlayer(0);
    print("NPC " .. tostring(npc:getUsername()) .. " asked to join group");
    player:Say(getText("IGUI_KnoxEvent_Player_Speech_NpcGroupAskJoin"));
    local group = player:getGroup()
    group:joinGroup(npc);
end

function askNpcToLeaveGroup(worldObjects, npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    local player = getSpecificPlayer(0);
    print("NPC " .. tostring(npc:getUsername()) .. " asked to leave group");
    player:Say(getText("IGUI_KnoxEvent_Player_Speech_NpcGroupKick"));
    local group = player:getGroup()
    group:leaveGroup(npc);
    if ISGroupNpcsUI.instance ~= nil then
        ISGroupNpcsUI.instance:populateList();
    end
end

------------------------------------------------------
----------------- SAFEHOUSE COMMANDS -----------------
------------------------------------------------------
function claimSafehouse(worldObjects, buildingDef, player)
    local result = claimPlayerSafehouse(buildingDef);
    if result then
        player:Say(getText("IGUI_KnoxEvent_Player_Speech_SafehouseClaimSuccess"));
    else
        player:Say(getText("IGUI_KnoxEvent_Player_Speech_SafehouseClaimFail"));
    end
end

function releaseSafehouse(worldObjects, player)
    releasePlayerSafehouse();
    player:Say(getText("IGUI_KnoxEvent_Player_Speech_SafehouseRelease"));
end

function tellNpcBarricade(worldObjects, npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    npc:setGoal("SafehouseSubTree");
    npc:setSubGoal("BarricadeSubTree");
end

function tellNpcChopTrees(worldObjects, npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    npc:setGoal("SafehouseSubTree");
    npc:setSubGoal("ChopTreesSubTree");
end

function tellNpcDumpCorpses(worldObjects, npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    npc:setGoal("SafehouseSubTree");
    npc:setSubGoal("CorpseDumpSubTree");
end

function tellNpcDumpLoot(worldObjects, npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    npc:setGoal("SafehouseSubTree");
    npc:setSubGoal("DumpLootSubTree");
end

function tellNpcGuard(worldObjects, npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    npc:setGoal("SafehouseSubTree");
    npc:setSubGoal("GuardSubTree");
end

function tellNpcRest(worldObjects, npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    npc:setGoal("SafehouseSubTree");
    npc:setSubGoal("RestSubTree");
end

------------------------------------------------------
------------------ ROAMING COMMANDS ------------------
------------------------------------------------------
function tellNpcFollow(worldObjects, npc)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    npc:setGoal("RoamingSubTree");
    npc:setSubGoal("FollowSubTree");
    print("NPC " .. tostring(npc:getUsername()) .. " told to follow player");
end

function tellNpcStay(npc, x, y, z)
    if npc == nil or not instanceof(npc, "IsoNpcPlayer") then
        print("Not a valid npc");
        return;
    end
    npc:setGoal("RoamingSubTree");
    npc:setSubGoal("StaySubTree");
    local tree = npc:getBehaviorTree();
    local staySubTreeNode = tree:getChildWithName("StaySubTree");
    local stayMovementNode = staySubTreeNode:getChildWithName("MovementSubTree");
    stayMovementNode:setData("MovementSubTreeTargetX", x);
    stayMovementNode:setData("MovementSubTreeTargetY", y);
    stayMovementNode:setData("MovementSubTreeTargetZ", z);
    print("NPC " .. tostring(npc:getUsername()) .. " told to stay at " .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z));
end

function tellNpcLoot(worldObjects, lootBuilding)
    local buildingDef = lootBuilding:getDef();
    local i = 0
    for _, npc in ipairs(selectedGroupNps) do
        npc:setGoal("LootingSubTree");
        npc:setSubGoal("");
        local tree = npc:getBehaviorTree();
        local goalNode = tree:getGoalNode();
        local lootNode = goalNode:getChildWithNameWithDepth("LootingSubTree", 1);

        lootNode:setData("EnterBuildingIsoBuilding", lootBuilding);
        lootNode:setData("LootingSubTreeLootBuilding", buildingDef);
        lootNode:setData("LootingSubTreeCategoryAmmo", lootAmmo);
        lootNode:setData("LootingSubTreeCategoryFood", lootFood);
        lootNode:setData("LootingSubTreeCategoryFirstAid", lootFirstAid);
        lootNode:setData("LootingSubTreeCategoryMats", lootMaterials);
        lootNode:setData("LootingSubTreeCategoryGuns", lootGuns);
        lootNode:setData("LootingSubTreeCategoryTools", lootTools);
        lootNode:setData("LootingSubTreeCategoryWater", lootWater);
        lootNode:setData("LootingSubTreeCategoryWeapons", lootWeapons);
        lootNode:setData("LootingSubTreeCategoryFinishedGoal", "RoamingSubTree");
        lootNode:setData("LootingSubTreeCategoryFinishedSubGoal", "FollowSubTree");

        print("NPC " .. tostring(npc:getUsername()) .. " told to loot building");
    end
end
