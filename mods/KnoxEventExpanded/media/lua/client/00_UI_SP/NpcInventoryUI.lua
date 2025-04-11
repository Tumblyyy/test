if isClient() or isServer() then return end

require "ISUI/ISInventoryPane"

NpcInventoryUI = {}
NpcInventoryUI.npcObj = nil;

function openNpcInventory(worldObjects, npc)
    NpcInventoryUI.npcObj = npc;
end

function NpcInventoryUI.addNpcInventoryContainer(page, step)
    if page == ISPlayerData[1].lootInventory and step == "buttonsAdded" and NpcInventoryUI.npcObj ~= nil then
        ISPlayerData[1].lootInventory:addContainerButton(NpcInventoryUI.npcObj:getInventory(), nil, "NPC", nil)
    end
end

Events.OnRefreshInventoryWindowContainers.Add(NpcInventoryUI.addNpcInventoryContainer)

local function checkCloseNpcMockContainer()
    if NpcInventoryUI.npcObj ~= nil then
        local player = getSpecificPlayer(0);
        local sx = player:getX();
        local sy = player:getY();
        local sz = player:getZ();
        local tx = NpcInventoryUI.npcObj:getX();
        local ty = NpcInventoryUI.npcObj:getY();
        local tz = NpcInventoryUI.npcObj:getZ();
        local dx = tx - sx;
        local dy = ty - sy;
        local dist = dx*dx + dy+dy;
        if dist >= 4 or sz ~= tz then
            NpcInventoryUI.npcObj = nil;
        end
    end
end

Events.OnTick.Add(checkCloseNpcMockContainer);

function NpcInventoryUI.onInventoryContextMenu(player, context, items)
    if NpcInventoryUI.npcObj == nil then
            return;
    end
    local primaryEquip = nil;
    local secondaryEquip = nil;
    local twoHanded = nil;
    local isEquipped = nil;
    local garment = nil;
    local backpack = nil;
    local drop = nil;
    items = ISInventoryPane.getActualItems(items)
    droppable = {};
    for _, item in ipairs(items) do
        if item:getContainer() ~= nil and item:getContainer() == NpcInventoryUI.npcObj:getInventory() then
            if item:isEquipped() then
                isEquipped = item;
            else
                if item:getCategory() == "Clothing" then
                    garment = item
                elseif instanceof(item, "InventoryContainer") and item:canBeEquipped() == "Back" then
                    backpack = item
                elseif (instanceof(item, "HandWeapon") and not item:isBroken()) then
                    if item:isRequiresEquippedBothHands() then
                        twoHanded = item;
                    else
                        primaryEquip = item;
                        secondaryEquip = item;
                        if item:isTwoHandWeapon()then
                            twoHanded = item;
                        end
                    end
                end
            end
            if not instanceof(item, "InventoryContainer") then
                table.insert(droppable, item);
            end
        end
    end
    if isEquipped and isEquipped:getContainer() ~= nil then
        context:addOption(getText("ContextMenu_Unequip") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.unequip, isEquipped);
    else
        if primaryEquip and primaryEquip:getContainer() ~= nil then
            context:addOption(getText("ContextMenu_Equip_Primary") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.equipPrimary, primaryEquip);
        end
        if secondaryEquip and secondaryEquip:getContainer() ~= nil then
            context:addOption(getText("ContextMenu_Equip_Secondary") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.equipSecondary, secondaryEquip);
        end
        if twoHanded and twoHanded:getContainer() ~= nil then
            context:addOption(getText("ContextMenu_Equip_Two_Hands") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.equipTwoHanded, twoHanded);
        end
        if garment and garment:getContainer() ~= nil then
            context:addOption(getText("ContextMenu_Wear") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.wear, garment);
        end
        if backpack and backpack:getContainer() ~= nil then
            context:addOption(getText("ContextMenu_Equip_on_your_Back") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.wearOnBack, backpack);
        end
    end
    if #droppable > 0 then
        context:addOption(getText("ContextMenu_Drop") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.drop, droppable);
    end
end

Events.OnFillInventoryObjectContextMenu.Add(NpcInventoryUI.onInventoryContextMenu)

function NpcInventoryUI.equipPrimary(npc, item)
    if npc:getPrimaryHandItem() == npc:getSecondaryHandItem() then
        npc:setSecondaryHandItem(nil);
    end
    npc:setPrimaryHandItem(item);
    npc:setPreferredWeapon(item);
end

function NpcInventoryUI.equipSecondary(npc, item)
    npc:setSecondaryHandItem(item);
end

function NpcInventoryUI.equipTwoHanded(npc, item)
    npc:setPrimaryHandItem(item);
    npc:setSecondaryHandItem(item);
    npc:setPreferredWeapon(item);
end

function NpcInventoryUI.wear(npc, item)
    npc:setWornItem(item:getBodyLocation(), item);
end

function NpcInventoryUI.wearOnBack(npc, item)
    npc:setClothingItem_Back(item);
end

function NpcInventoryUI.unequip(npc, item)
    npc:removeWornItem(item);
    if item == npc:getPrimaryHandItem() then
        if (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) and item == npc:getSecondaryHandItem() then
            npc:setSecondaryHandItem(nil);
        end
        npc:setPrimaryHandItem(nil);
    end
    if item == npc:getSecondaryHandItem() then
        if (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) and item == npc:getPrimaryHandItem() then
            npc:setPrimaryHandItem(nil);
        end
        npc:setSecondaryHandItem(nil);
    end
    npc:setPreferredWeapon(nil);
end

function NpcInventoryUI.drop(npc, items)
    for _, item in ipairs(items) do
        npc:removeWornItem(item);
        if item == npc:getPrimaryHandItem() then
            if (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) and item == npc:getSecondaryHandItem() then
                npc:setSecondaryHandItem(nil);
            end
            npc:setPrimaryHandItem(nil);
        end
        if item == npc:getSecondaryHandItem() then
            if (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) and item == npc:getPrimaryHandItem() then
                npc:setPrimaryHandItem(nil);
            end
            npc:setSecondaryHandItem(nil);
        end
        npc:setPreferredWeapon(nil);
        local floor = ItemContainer.new();
        floor:setType("floor");
        floor:DoAddItemBlind(item);
        local square = npc:getCurrentSquare();
		square:AddWorldInventoryItem(item, 0, 0, 0, true);
    end
end

local transferItemsByWeightOrig = ISInventoryPane.transferItemsByWeight
function ISInventoryPane:transferItemsByWeight(items, container)
    if NpcInventoryUI.npcObj == nil then
        transferItemsByWeightOrig(self, items, container);
        return;
    end

    items = ISInventoryPane.getActualItems(items)
    for _, item in ipairs(items) do
        if item:isEquipped() then
            local npc = NpcInventoryUI.npcObj;
            npc:removeWornItem(item);
            if item == npc:getPrimaryHandItem() then
                if (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) and item == npc:getSecondaryHandItem() then
                    npc:setSecondaryHandItem(nil);
                end
                npc:setPrimaryHandItem(nil);
            end
            if item == npc:getSecondaryHandItem() then
                if (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) and item == npc:getPrimaryHandItem() then
                    npc:setPrimaryHandItem(nil);
                end
                npc:setSecondaryHandItem(nil);
            end
        end
    end
    transferItemsByWeightOrig(self, items, container);
end

local transferItemsOrig = ISInventoryPaneContextMenu.transferItems
ISInventoryPaneContextMenu.transferItems = function(items, playerInv, player, dontWalk)
    if NpcInventoryUI.npcObj == nil then
        transferItemsOrig(items, playerInv, player, dontWalk);
        return;
    end

    items = ISInventoryPane.getActualItems(items)
    for _, item in ipairs(items) do
        if item:isEquipped() then
            local npc = NpcInventoryUI.npcObj;
            npc:removeWornItem(item);
            if item == npc:getPrimaryHandItem() then
                if (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) and item == npc:getSecondaryHandItem() then
                    npc:setSecondaryHandItem(nil);
                end
                npc:setPrimaryHandItem(nil);
            end
            if item == npc:getSecondaryHandItem() then
                if (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) and item == npc:getPrimaryHandItem() then
                    npc:setPrimaryHandItem(nil);
                end
                npc:setSecondaryHandItem(nil);
            end
        end
    end
    transferItemsOrig(items, playerInv, player, dontWalk);
end

local dropItemOrig = ISInventoryPaneContextMenu.dropItem;
ISInventoryPaneContextMenu.dropItem = function(item, player)
    if NpcInventoryUI.npcObj == nil then
        dropItemOrig(item, player);
        return;
    end

    if item:getContainer() ~= NpcInventoryUI.npcObj:getInventory() then
        dropItemOrig(item, player);
    end
    if not (instanceof(item, "InventoryContainer") and item:isEquipped()) then
        local items = {};
        table.insert(items, item)
        NpcInventoryUI.drop(NpcInventoryUI.npcObj, items);
    end
end