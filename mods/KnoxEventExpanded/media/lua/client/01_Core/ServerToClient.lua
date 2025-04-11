if not isClient() or isServer()  then return end;

require "00_UI_MP/ISGroupNpcsUI"

masterNpcList = {}
groupNpcList = {}
isGroupAggressive = false;
isGroupRetreating = false;

local function serverCommandHandler(_module, _command, _data)
    if _module == "KnoxEventNpcControl" then
        if _command == "NpcSync" then
            if _data ~= nil then
                masterNpcList = _data
            end
        elseif _command == "NpcGroupUpdate" then
            local playerData = getPlayerData(0);
            if _data ~= nil then
                local index = tonumber(_data["index"]) + 1;
                local npcObj = {};
                npcObj["id"] = tonumber(_data["id"]);
                npcObj["name"] = tostring(_data["name"]);
                npcObj["task"] = tostring(_data["task"]);
                npcObj["subtask"] = tostring(_data["subtask"]);
                npcObj["relation"] = tostring(_data["relation"]);
                groupNpcList[index] = npcObj;
                if playerData ~= nil then
                    playerData.npcOverlayUI:populateList(groupNpcList);
                end
            end
        elseif _command == "NpcSpawned" then
            print("Got data " .. tostring(_data))
            local npc_id = _data["id"]
            local npc_name = _data["name"]
            table.insert(masterNpcList, npc_id, npc_name);
        elseif _command == "NpcGroupInfo" then
            groupNpcList = {}
            local playerData = getPlayerData(0);
            if _data ~= nil then
                for key, value in pairs(_data) do
                    table.insert(groupNpcList, key, value)
                end
            end
            if playerData ~= nil then
                playerData.npcOverlayUI:populateList(groupNpcList);
            end
        elseif _command == "NpcGroupAggressiveInfo" then
            if _data["hostile"] == "true" then
                isGroupAggressive = true;
            elseif _data["hostile"] == "false" then
                isGroupAggressive = false
            end
        elseif _command == "NpcGroupRetreatingInfo" then
            if _data["retreating"] == "true" then
                isGroupRetreating = true;
            elseif _data["retreating"] == "false" then
                isGroupRetreating = false
            end
        elseif _command == "NpcDialogueStart" then
            local npcId = tonumber(_data["id"]);
            local npcName = tostring(_data["name"]);
            local playerData = getPlayerData(0);
            if npcId and npcName and playerData ~= nil then
                playerData.npcDialogueUI.npcId = npcId;
                playerData.npcDialogueUI.npcName = npcName;
                playerData.npcDialogueUI:setVisible(true);
            end
        elseif _command == "NpcDialogueStop" then
            local playerData = getPlayerData(0);
            if playerData ~= nil then
                playerData.npcDialogueUI.npcId = nil;
                playerData.npcDialogueUI.npcName = nil;
                playerData.npcDialogueUI:setVisible(false);
            end
        end
    elseif _module == "KnoxEventNpcInventoryControl" then
        if _command == "NpcRequestInventory" then
            NpcInventoryUI.mockContainer:removeAllItems();
            NpcInventoryUI.mockContainerLookup = {};
            NpcInventoryUI.mockContainerEquipped = {};
            for _,v in pairs(_data["items"]) do
                if v.fullType then
                    local item = InventoryItemFactory.CreateItem(v.fullType);
                    if item then
                        -- Double -> Long conversion is busted?
                        NpcInventoryUI.mockContainerLookup[item:getID()] = v["itemId"];
                        NpcInventoryUI.mockContainer:AddItem(item);
                        if v["isEquip"] ~= nil then
                            NpcInventoryUI.mockContainerEquipped[item:getID()] = v["isEquip"];
                        end
                        if (item:IsWeapon() or item:IsClothing()) and v["condition"] ~= nil then
                            item:setCondition(tonumber(v["condition"]));
                        end
                        if item:IsWeapon() and v["isContainsClip"] ~= nil then
                            item:setContainsClip(v["isContainsClip"]);
                        end
                        if item:IsWeapon() and v["currentAmmoCount"] ~= nil then
                            item:setCurrentAmmoCount(tonumber(v["currentAmmoCount"]));
                        end
                        if item:IsWeapon() and v["isRoundChambered"] ~= nil then
                            item:setRoundChambered(v["isRoundChambered"]);
                        end
                    end
                end
            end
        end
    elseif _module == "KnoxEventNpcRoamingControl" then
        if _command == "NpcHelpRequested" then
            if ISWorldMap_instance ~= nil then
                local tx = tonumber(_data["x"]);
                local ty = tonumber(_data["y"]);
                --ISWorldMap_instance:addSafehouse(tx, ty);
            end
        end
    end
end

local function OnConnectedNpcHandler()
	sendClientCommand("KnoxEventNpcControl", "NpcSync", {})
end

if isClient() then
    Events.OnServerCommand.Add(serverCommandHandler)
    Events.OnConnected.Add(OnConnectedNpcHandler)
end
