require "client/00_UI_MP/NpcOverlayUI"
require "client/00_UI_SP/NpcOverlayUI"
require "ISUI/PlayerData"
require "ISUI/PlayerDataObject"

local oldRemoveInventoryUI = removeInventoryUI;
function removeInventoryUI(id)
    oldRemoveInventoryUI(id);
    local data = getPlayerData(id);
    if data == nil then return end;

    if data.npcOverlayUI ~= nil then
        data.npcOverlayUI:removeFromUIManager();
    end

    if data.npcLootOverlayUI ~= nil then
        data.npcLootOverlayUI:removeFromUIManager();
    end

    if data.npcAggressiveOverlayUI ~= nil then
        data.npcAggressiveOverlayUI:removeFromUIManager();
    end

    if data.npcRetreatOverlayUI ~= nil then
        data.npcRetreatOverlayUI:removeFromUIManager();
    end

    if data.npcDialogueUI ~= nil then
        data.npcDialogueUI:removeFromUIManager();
    end
end