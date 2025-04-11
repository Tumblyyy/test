if not isClient() or isServer()  then return end;

------------------------------------------------------
------------------- DEBUG COMMANDS -------------------
------------------------------------------------------
function testHunger(worldObjects, npc)
    print("Testing hunger for npc with id " .. tostring(npc));
    local data = {npcId=npc};
    sendClientCommand("KnoxEventDebug", "NpcTestHunger", data);
end

function testThirst(worldObjects, npc)
    print("Testing thirst for npc with id " .. tostring(npc));
    local data = {npcId=npc};
    sendClientCommand("KnoxEventDebug", "NpcTestThrist", data);
end

function testExhaustion(worldObjects, npc)
    print("Testing exhaustion for npc with id " .. tostring(npc));
    local data = {npcId=npc};
    sendClientCommand("KnoxEventDebug", "NpcTestExhaustion", data);
end

function toggleNpcBaseDebug(worldObjects, npc)
    print("Toggling NpcBase debugging for npc with id " .. tostring(npc));
    local data = {npcId=npc};
    sendClientCommand("KnoxEventDebug", "ToggleNpcBaseDebug", data);
end

function toggleNpcTreeDebug(worldObjects, npc)
    print("Toggling Npc tree debugging for npc with id " .. tostring(npc));
    local data = {npcId=npc};
    sendClientCommand("KnoxEventDebug", "ToggleNpcTreeDebug", data);
end

function dumpMemories(worldObjects, npc)
    print("Dump memories for npc with id " .. tostring(npc));
    local data = {npcId=npc};
    sendClientCommand("KnoxEventDebug", "NpcDumpMemoriesDebug", data);
end

function setShowNpcs(show)
    print("Set show npcs on map " .. tostring(show));
    local data = {showNpcs=tostring(show)};
    sendClientCommand("KnoxEventDebug", "ShowNpcsDebug", data);
end

------------------------------------------------------
-----------------  GROUP SETTINGS   ------------------
------------------------------------------------------
function toggleNpcAggressive()
    local data = {};
    print("Toggling Npc aggressiveness");
    if isGroupAggressive then
        -- Will NOT be aggressive after
        getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_Aggressive"));
    else
        -- Will be aggressive after
        getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_Passive"));
    end
    sendClientCommand("KnoxEventNpcControl", "NpcToggleGroupAggressive", data);
end

function toggleNpcRetreat()
    local data = {};
    if isGroupRetreating then
        -- Will NOT be retreating after
        getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_Fight"));
    else
        -- Will be retreating after
        getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_Retreat"));
    end
    print("Toggling Npc retreat/fight");
    sendClientCommand("KnoxEventNpcControl", "NpcToggleGroupRetreat", data);
end

function setNpcChopTreesArea(x1, y1, x2, y2)
    local data = {startX=x1, startY=y1, endX=x2, endY=y2};
    print("Setting Npc chop tree area");
    sendClientCommand("KnoxEventNpcControl", "NpcSetGroupChopTreesArea", data);
end

function setNpcCorpseClearArea(x1, y1, x2, y2)
    local data = {startX=x1, startY=y1, endX=x2, endY=y2};
    print("Setting Npc corpse dump area");
    sendClientCommand("KnoxEventNpcControl", "NpcSetGroupCorpseClearArea", data);
end

function setNpcCorpseDumpArea(x1, y1, x2, y2)
    local data = {startX=x1, startY=y1, endX=x2, endY=y2};
    print("Setting Npc corpse dump area");
    sendClientCommand("KnoxEventNpcControl", "NpcSetGroupCorpseDumpArea", data);
end

function setNpcGuardArea(x1, y1, x2, y2)
    local data = {startX=x1, startY=y1, endX=x2, endY=y2};
    print("Setting Npc guard area");
    sendClientCommand("KnoxEventNpcControl", "NpcSetGroupGuardArea", data);
end

------------------------------------------------------
------------------ INTERACT COMMANDS------------------
------------------------------------------------------
function talkToNpc(worldObjects, npc)
    print("Talking to Npc with id " .. tostring(npc));
    local data = {npcId=npc};
    sendClientCommand("KnoxEventNpcControl", "NpcSpeak", data);
end

function smallTalkToNpc(npc)
    print("Small Talking to Npc with id " .. tostring(npc));
    local data = {npcId=npc};
    sendClientCommand("KnoxEventNpcControl", "NpcSmallTalk", data);
end

function smallTalkWeather(npc)
    print("Small talk weather with npc with id " .. tostring(npc));
    local data = {npcId=npc};
    getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_SpeechSmallTalk"));
    sendClientCommand("KnoxEventNpcControl", "NpcSmallTalkWeather", data);
end

function smallTalkAge(npc)
    print("Small talk age with npc with id " .. tostring(npc));
    local data = {npcId=npc};
    getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Npc_Dialogue_SmallTalkAge"));
    sendClientCommand("KnoxEventNpcControl", "NpcSmallTalkAge", data);
end

function smallTalkOccupation(npc)
    print("Small talk occupation with npc with id " .. tostring(npc));
    local data = {npcId=npc};
    getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Npc_Dialogue_SmallTalkOccupation"));
    sendClientCommand("KnoxEventNpcControl", "NpcSmallTalkOccupation", data);
end

function askRecentToNpc(npc)
    print("Ask recent events to Npc with id " .. tostring(npc));
    local data = {npcId=npc};
    getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_SpeechRecent"));
    sendClientCommand("KnoxEventNpcControl", "NpcAskRecent", data);
end

function stopTalkingToNpc(npc)
    print("Stop talking to Npc with id " .. tostring(npc));
    local data = {npcId=npc};
    getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_SpeechGoodbye"));
    sendClientCommand("KnoxEventNpcControl", "NpcStopTalk", data);
end

function openNpcInventory(worldObjects, npc)
    NpcInventoryUI.mockContainerOpen = true;
    NpcInventoryUI.npcObj = npc;
    requestInventoryNpc(npc:getOnlineID());
end

function askNpcToJoinGroup(npc)
    print("Asking Npc to join group " .. tostring(npcObj) .. " with id " .. tostring(npc));
    local data = {npcId=npc};
    getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_NpcGroupAskJoin"))
    sendClientCommand("KnoxEventNpcControl", "NpcJoinGroup", data);
end

function askNpcToLeaveGroup(worldObjects, npc)
    print("Asking Npc to leave group " .. tostring(npcObj) .. " with id " .. tostring(npc));
    local data = {npcId=npc};
    getSpecificPlayer(0):Say(getText("IGUI_KnoxEvent_Player_Speech_NpcGroupKick"))
    sendClientCommand("KnoxEventNpcControl", "NpcLeaveGroup", data);
end

------------------------------------------------------
----------------- INVENTORY COMMANDS------------------
------------------------------------------------------
function requestInventoryNpc(npc)
    print("Requesting inventory for Npc with id " .. tostring(npc));
    local data = {npcId=npc};
    sendClientCommand("KnoxEventNpcInventoryControl", "NpcRequestInventory", data);
end

function takeNpcItem(npc, itemId)
    print("Taking an item " .. tostring(itemId) .. " from Npc with id " .. tostring(npc));
    local data = {npcId=npc,item=itemId};
    sendClientCommand("KnoxEventNpcInventoryControl", "NpcTakeItem", data);
end

function giveNpcItem(npc, itemString, condition, hasClip, ammo, chambered)
    print("Giving Npc with id " .. tostring(npc) .. " an item: " .. tostring(itemString));
    local data = {npcId=npc,item=itemString};
    if condition ~= nil then
        data["condition"] = condition;
    end
    if hasClip ~= nil then
        data["isContainsClip"] = hasClip;
    end
    if ammo ~= nil then
        data["currentAmmoCount"] = ammo;
    end
    if chambered ~= nil then
        data["isRoundChambered"] = chambered;
    end
    sendClientCommand("KnoxEventNpcInventoryControl", "NpcGiveItem", data);
    requestInventoryNpc(npc);
end

function equipPrimaryNpc(npc, itemId)
    print("Unequipping item with id " .. tostring(itemId) .. " from Npc with id " .. tostring(npc));
    local data = {npcId=npc,item=itemId};
    sendClientCommand("KnoxEventNpcInventoryControl", "NpcEquipPrimary", data);
    requestInventoryNpc(npc);
end

function equipSecondaryNpc(npc, itemId)
    print("Unequipping item with id " .. tostring(itemId) .. " from Npc with id " .. tostring(npc));
    local data = {npcId=npc,item=itemId};
    sendClientCommand("KnoxEventNpcInventoryControl", "NpcEquipSecondary", data);
    requestInventoryNpc(npc);
end

function equipTwoHandedNpc(npc, itemId)
    print("Unequipping item with id " .. tostring(itemId) .. " from Npc with id " .. tostring(npc));
    local data = {npcId=npc,item=itemId};
    sendClientCommand("KnoxEventNpcInventoryControl", "NpcEquipTwoHanded", data);
    requestInventoryNpc(npc);
end

function wearNpc(npc, itemId)
    print("Wear item with id " .. tostring(itemId) .. " from Npc with id " .. tostring(npc));
    local data = {npcId=npc,item=itemId};
    sendClientCommand("KnoxEventNpcInventoryControl", "NpcWear", data);
    requestInventoryNpc(npc);
end

function wearOnBackNpc(npc, itemId)
    print("Wearing item with id " .. tostring(itemId) .. " on back for Npc with id " .. tostring(npc));
    local data = {npcId=npc,item=itemId};
    sendClientCommand("KnoxEventNpcInventoryControl", "NpcWearOnBack", data);
    requestInventoryNpc(npc);
end

function unequipNpc(npc, itemId)
    print("Unequip item with id " .. tostring(itemId) .. " from Npc with id " .. tostring(npc));
    local data = {npcId=npc,item=itemId};
    sendClientCommand("KnoxEventNpcInventoryControl", "NpcUnequip", data);
    requestInventoryNpc(npc);
end

function dropNpc(npc, itemId)
    print("Dropping item with id " .. tostring(itemId) .. " from Npc with id " .. tostring(npc));
    local data = {npcId=npc,item=itemId};
    sendClientCommand("KnoxEventNpcInventoryControl", "NpcDrop", data);
    requestInventoryNpc(npc);
end

------------------------------------------------------
----------------- SAFEHOUSE COMMANDS -----------------
------------------------------------------------------
function tellNpcBarricade(worldObjects, npc)
    print("Asking Npc with id " .. tostring(npc) .. " to barricade base...");
    local data = {npcId=npc};
    sendClientCommand("KnoxEventNpcSafeHouseControl", "NpcBarricade", data)
end

function tellNpcChopTrees(worldObjects, npc)
    print("Asking Npc with id " .. tostring(npc) .. " to chop trees...");
    local data = {npcId=npc};
    sendClientCommand("KnoxEventNpcSafeHouseControl", "NpcChopTrees", data)
end

function tellNpcDumpCorpses(worldObjects, npc)
    print("Asking Npc with id " .. tostring(npc) .. " to dump corpses...");
    local data = {npcId=npc};
    sendClientCommand("KnoxEventNpcSafeHouseControl", "NpcCorpseDump", data)
end

function tellNpcDumpLoot(worldObjects, npc)
    print("Asking Npc with id " .. tostring(npc) .. " to dump loot...");
    local data = {npcId=npc};
    sendClientCommand("KnoxEventNpcSafeHouseControl", "NpcDumpLoot", data)
end

function tellNpcGuard(worldObjects, npc)
    print("Asking Npc with id " .. tostring(npc) .. " to stand guard...");
    local data = {npcId=npc};
    sendClientCommand("KnoxEventNpcSafeHouseControl", "NpcGuard", data)
end

function tellNpcRest(worldObjects, npc)
    print("Asking Npc with id " .. tostring(npc) .. " to go rest...");
    local data = {npcId=npc};
    sendClientCommand("KnoxEventNpcSafeHouseControl", "NpcRest", data)
end

------------------------------------------------------
------------------ ROAMING COMMANDS ------------------
------------------------------------------------------
function tellNpcFollow(worldObjects, npc)
    print("Asking Npc with id " .. tostring(npc) .. " to follow");
    local data = {npcId=npc};
    sendClientCommand("KnoxEventNpcRoamingControl", "NpcFollow", data)
end

function tellNpcStay(npc, x, y, z)
    print("Asking Npc with id " .. tostring(npc) .. " to stay");
    local data = {npcId=npc,tx=x,ty=y,tz=z};
    sendClientCommand("KnoxEventNpcRoamingControl", "NpcStay", data)
end

function tellNpcLoot(worldObjects, buildingXCoord, buildingYCoord)
    print("Asking Npcs to loot building at " .. tostring(buildingXCoord) .. "," .. tostring(buildingYCoord) .. ")");
    local data = {npcs=selectedGroupNps,buildingX=buildingXCoord,buildingY=buildingYCoord,ammo=lootAmmo,firstaid=lootFirstAid,food=lootFood,guns=lootGuns,materials=lootMaterials,tools=lootTools,water=lootWater,weapons=lootWeapons};
    sendClientCommand("KnoxEventNpcRoamingControl", "NpcLoot", data)
end