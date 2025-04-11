local function handleKnoxEventNpcInventoryControl(_command, _player, _table)
    local npcId = tonumber(_table["npcId"]);
    local npcObj = KnoxEventNpcAPI.instance:getNpcFromOnlineId(npcId);
    if _command == "NpcRequestInventory" then
        local npcInventory = npcObj:getInventory();
        local it = npcInventory:getItems();
        local npcItems = {}
        for i = 0, it:size()-1 do
            local item = it:get(i);
            local itemTable = {};
            itemTable["fullType"] = item:getFullType();
            itemTable["itemId"] = item:getID();
            itemTable["isEquip"] = item:isEquipped();
            if item:IsWeapon() then
                itemTable["condition"] = item:getCondition();
                itemTable["isContainsClip"] = item:isContainsClip();
                itemTable["currentAmmoCount"] = item:getCurrentAmmoCount();
                itemTable["isRoundChambered"] = item:isRoundChambered();
            elseif item:IsClothing() then
                itemTable["condition"] = item:getCondition();
            end
            table.insert(npcItems, itemTable);
        end
        sendServerCommand("KnoxEventNpcInventoryControl", "NpcRequestInventory", {items=npcItems})
    elseif _command == "NpcTakeItem" then
        local itemString = _table["item"];
        local item = npcObj:getItemFromLua(itemString);
        local npcInventory = npcObj:getInventory();
        npcObj:removeWornItem(item);
        if npcObj:getPrimaryHandItem() == item then
            npcObj:setPrimaryHandItem(nil);
        end
        if npcObj:getSecondaryHandItem() == item then
            npcObj:setSecondaryHandItem(nil);
        end
        item:getContainer():DoRemoveItem(item);
        print("Taking item with id " .. tostring(itemString) .. " from NPC with id " .. tostring(npcId));
    elseif _command == "NpcGiveItem" then
        local itemString = tostring(_table["item"]);
        local npcInventory = npcObj:getInventory();
        local item = InventoryItemFactory.CreateItem(itemString);
        npcInventory:addItem(item);
        if _table["condition"] ~= nil then
            item:setCondition(tonumber(_table["condition"]));
        end
        if _table["isContainsClip"] ~= nil then
            item:setContainsClip(_table["isContainsClip"]);
        end
        if _table["currentAmmoCount"] ~= nil then
            item:setCurrentAmmoCount(tonumber(_table["currentAmmoCount"]));
        end
        if _table["isRoundChambered"] ~= nil then
            item:setRoundChambered(_table["isRoundChambered"]);
        end
        print("Giving item " .. tostring(itemString) .. " to NPC with id " .. tostring(npcId));
    elseif _command == "NpcEquipPrimary" then
        local itemString = _table["item"];
        local item = npcObj:getItemFromLua(itemString);
        if npcObj:getPrimaryHandItem() == npcObj:getSecondaryHandItem() then
            npcObj:setSecondaryHandItem(nil);
        end
        npcObj:setPrimaryHandItem(item);
        npcObj:setPreferredWeapon(item);
    elseif _command == "NpcEquipSecondary" then
        local itemString = _table["item"];
        local item = npcObj:getItemFromLua(itemString);
        npcObj:setSecondaryHandItem(item);
    elseif _command == "NpcEquipTwoHanded" then
        local itemString = _table["item"];
        local item = npcObj:getItemFromLua(itemString);
        npcObj:setPrimaryHandItem(item);
        npcObj:setSecondaryHandItem(item);
        npcObj:setPreferredWeapon(item);
    elseif _command == "NpcWear" then
        local itemString = _table["item"];
        local item = npcObj:getItemFromLua(itemString);
        npcObj:setWornItem(item:getBodyLocation(), item);
    elseif _command == "NpcWearOnBack" then
        local itemString = _table["item"];
        local item = npcObj:getItemFromLua(itemString);
        npcObj:setWornItem(item:canBeEquipped(), item);
    elseif _command == "NpcUnequip" then
        local itemString = _table["item"];
        local item = npcObj:getItemFromLua(itemString);
        npcObj:removeWornItem(item);
        if item == npcObj:getPrimaryHandItem() then
            if (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) and item == npcObj:getSecondaryHandItem() then
                npcObj:setSecondaryHandItem(nil);
            end
            npcObj:setPrimaryHandItem(nil);
        end
        if item == npcObj:getSecondaryHandItem() then
            if (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) and item == npcObj:getPrimaryHandItem() then
                npcObj:setPrimaryHandItem(nil);
            end
            npcObj:setSecondaryHandItem(nil);
        end
        npcObj:setPreferredWeapon(nil);
    elseif _command == "NpcDrop" then
        local itemString = _table["item"];
        local item = npcObj:getItemFromLua(itemString);
        npcObj:removeWornItem(item);
        if item == npcObj:getPrimaryHandItem() then
            if (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) and item == npcObj:getSecondaryHandItem() then
                npcObj:setSecondaryHandItem(nil);
            end
            npcObj:setPrimaryHandItem(nil);
        end
        if item == npcObj:getSecondaryHandItem() then
            if (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) and item == npcObj:getPrimaryHandItem() then
                npcObj:setPrimaryHandItem(nil);
            end
            npcObj:setSecondaryHandItem(nil);
        end
        npcObj:setPreferredWeapon(item);
        local floor = ItemContainer.new();
        floor:setType("floor");
        floor:DoAddItemBlind(item);
        local square = npcObj:getCurrentSquare();
		square:AddWorldInventoryItem(item, 0, 0, 0, true);
    end
end

local function npcInventoryControlCommandHandler(_module, _command, _player, _table)
    if _module == "KnoxEventNpcInventoryControl" then
        print("Received command " .. tostring(_command) .. " for module " .. tostring(_module));
        handleKnoxEventNpcInventoryControl(_command, _player, _table);
    end
end

Events.OnClientCommand.Add(npcInventoryControlCommandHandler)