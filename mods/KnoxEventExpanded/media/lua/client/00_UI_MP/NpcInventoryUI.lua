if not isClient() or isServer() then return end

require "ISUI/ISInventoryPane"

NpcInventoryUI = {}
NpcInventoryUI.mockContainerOpen = false;
NpcInventoryUI.mockContainer = ItemContainer.new();
NpcInventoryUI.mockContainer:setType("npc");
NpcInventoryUI.mockContainerLookup = {};
NpcInventoryUI.mockContainerEquipped = {};
NpcInventoryUI.npcObj = nil;

function NpcInventoryUI.addNpcMockContainer(page, step)
    if page == ISPlayerData[1].lootInventory and step == "buttonsAdded" and NpcInventoryUI.mockContainerOpen and NpcInventoryUI.npcObj ~= nil then
        ISPlayerData[1].lootInventory:addContainerButton(NpcInventoryUI.mockContainer, nil, "NPC", nil)
    end
end

Events.OnRefreshInventoryWindowContainers.Add(NpcInventoryUI.addNpcMockContainer)

local function checkCloseNpcMockContainer()
    if NpcInventoryUI.mockContainerOpen and NpcInventoryUI.npcObj ~= nil then
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
            NpcInventoryUI.mockContainerOpen = false;
            NpcInventoryUI.npcObj = nil;
            NpcInventoryUI.mockContainerLookup = {};
            NpcInventoryUI.mockContainerEquipped = {};
        end
    end
end

Events.OnTick.Add(checkCloseNpcMockContainer);

local transferItemsByWeightOrig = ISInventoryPane.transferItemsByWeight
function ISInventoryPane:transferItemsByWeight(items, container)
    if not NpcInventoryUI.mockContainerOpen then
        transferItemsByWeightOrig(self, items, container);
        return;
    end

    items = ISInventoryPane.getActualItems(items)
    local filteredItems = {};
    for _, item in ipairs(items) do
        if container:getType() == "npc" or (item:getContainer() ~= nil and item:getContainer():getType() == "npc") then
            if not instanceof(item, "InventoryContainer") then
                table.insert(filteredItems, item);
            end
        else
            table.insert(filteredItems, item);
        end
    end
    transferItemsByWeightOrig(self, filteredItems, container);
end

local transferItemsOrig = ISInventoryPaneContextMenu.transferItems
ISInventoryPaneContextMenu.transferItems = function(items, playerInv, player, dontWalk)
    if not NpcInventoryUI.mockContainerOpen then
        transferItemsOrig(items, playerInv, player, dontWalk);
        return;
    end

    items = ISInventoryPane.getActualItems(items)
    local filteredItems = {};
    for i, item in ipairs(items) do
        if item:getContainer() ~= nil and item:getContainer():getType() == "npc" then
            if not instanceof(item, "InventoryContainer") then
                table.insert(filteredItems, item);
            end
        else
            table.insert(filteredItems, item);
        end
    end
    transferItemsOrig(filteredItems, playerInv, player, dontWalk);
end

local dropItemOrig = ISInventoryPaneContextMenu.dropItem;
ISInventoryPaneContextMenu.dropItem = function(item, player)
    if not NpcInventoryUI.mockContainerOpen then
        dropItemOrig(item, player);
        return;
    end

    if item:getContainer() ~= nil and item:getContainer():getType() ~= "npc" then
        dropItemOrig(item, player);
    end
    if not (instanceof(item, "InventoryContainer") and NpcInventoryUI.mockContainerEquipped[item:getID()]) then
        local items = {};
        table.insert(items, item)
        NpcInventoryUI.drop(NpcInventoryUI.npcObj, items);
    end
end

local createMenuOrig = ISInventoryPaneContextMenu.createMenu;
ISInventoryPaneContextMenu.createMenu = function(player, isInPlayerInventory, origItems, x, y, origin)
    local isNpcContainer = false;
    local items = ISInventoryPane.getActualItems(origItems);
    for _, item in ipairs(items) do
        if item:getContainer() ~= nil and item:getContainer():getType() == "npc" then
            isNpcContainer = true;
            break;
        end
    end
    if not isNpcContainer then
        createMenuOrig(player, isInPlayerInventory, origItems, x, y, origin);
        return;
    end
    local context = ISContextMenu.get(player, x, y);
    local primaryEquip = nil;
    local secondaryEquip = nil;
    local twoHanded = nil;
    local isEquipped = nil;
    local garment = nil;
    local backpack = nil;
    local drop = nil;
    droppable = {};
    for _, item in ipairs(items) do
        if item:getContainer() ~= nil and item:getContainer():getType() == "npc" then
            if NpcInventoryUI.mockContainerEquipped[item:getID()] then
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
    if not isInPlayerInventory and not backpack then
        ISInventoryPaneContextMenu.doGrabMenu(context, items, player);
    end
    if isEquipped and isEquipped:getContainer() ~= nil and isEquipped:getContainer():getType() == "npc" then
        context:addOption(getText("ContextMenu_Unequip") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.unequip, isEquipped);
    else
        if primaryEquip and primaryEquip:getContainer() ~= nil and primaryEquip:getContainer():getType() == "npc" then
            context:addOption(getText("ContextMenu_Equip_Primary") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.equipPrimary, primaryEquip);
        end
        if secondaryEquip and secondaryEquip:getContainer() ~= nil and secondaryEquip:getContainer():getType() == "npc" then
            context:addOption(getText("ContextMenu_Equip_Secondary") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.equipSecondary, secondaryEquip);
        end
        if twoHanded and twoHanded:getContainer() ~= nil and twoHanded:getContainer():getType() == "npc" then
            context:addOption(getText("ContextMenu_Equip_Two_Hands") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.equipTwoHanded, twoHanded);
        end
        if garment and garment:getContainer() ~= nil and garment:getContainer():getType() == "npc"  then
            context:addOption(getText("ContextMenu_Wear") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.wear, garment);
        end
        if backpack and backpack:getContainer() ~= nil and backpack:getContainer():getType() == "npc" then
            context:addOption(getText("ContextMenu_Equip_on_your_Back") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.wearOnBack, backpack);
        end
    end
    if #droppable > 0 then
        context:addOption(getText("ContextMenu_Drop") .. " (NPC)", NpcInventoryUI.npcObj, NpcInventoryUI.drop, droppable);
    end
end

function NpcInventoryUI.equipPrimary(npc, item)
    equipPrimaryNpc(npc:getOnlineID(), tostring(NpcInventoryUI.mockContainerLookup[item:getID()]));
end

function NpcInventoryUI.equipSecondary(npc, item)
    equipSecondaryNpc(npc:getOnlineID(), tostring(NpcInventoryUI.mockContainerLookup[item:getID()]));
end

function NpcInventoryUI.equipTwoHanded(npc, item)
    equipTwoHandedNpc(npc:getOnlineID(), tostring(NpcInventoryUI.mockContainerLookup[item:getID()]));
end

function NpcInventoryUI.wear(npc, item)
    wearNpc(npc:getOnlineID(), tostring(NpcInventoryUI.mockContainerLookup[item:getID()]));
end

function NpcInventoryUI.wearOnBack(npc, item)
    wearOnBackNpc(npc:getOnlineID(), tostring(NpcInventoryUI.mockContainerLookup[item:getID()]));
end

function NpcInventoryUI.unequip(npc, item)
    unequipNpc(npc:getOnlineID(), tostring(NpcInventoryUI.mockContainerLookup[item:getID()]));
end

function NpcInventoryUI.drop(npc, items)
    for _, item in ipairs(items) do
        dropNpc(npc:getOnlineID(), tostring(NpcInventoryUI.mockContainerLookup[item:getID()]));
    end
end