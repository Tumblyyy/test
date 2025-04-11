require "client/00_UI_MP/NpcOverlayUI"
require "client/00_UI_SP/NpcOverlayUI"
require "ISUI/PlayerData"
require "ISUI/PlayerDataObject"

createInventoryInterfaceOrig = ISPlayerDataObject.createInventoryInterface;
function ISPlayerDataObject:createInventoryInterface()
    createInventoryInterfaceOrig(self);
    local x = getPlayerScreenLeft(self.id)
    local y = getPlayerScreenTop(self.id)
    local w = getPlayerScreenWidth(self.id)
    local h = getPlayerScreenHeight(self.id)

    local x2, y2 = x + 15, y + self.equipped:getHeight() + 20;
    self.safetyUI = ISSafetyUI:new(x2, y2, self.id);
    self.safetyUI:initialise();
    self.safetyUI:addToUIManager();
    self.safetyUI:setVisible(true);
    self.equipped:backMost()

    self.npcOverlayUI = NpcOverlayUI:new();
    self.npcOverlayUI:initialise();
    self.npcOverlayUI:addToUIManager();

    self.npcLootOverlayUI = NpcLootOverlayUI:new();
    self.npcLootOverlayUI:initialise();
    self.npcLootOverlayUI:addToUIManager();

    self.npcAggressiveOverlayUI = NpcAggressiveOverlayUI:new();
    self.npcAggressiveOverlayUI:initialise();
    self.npcAggressiveOverlayUI:addToUIManager();

    self.npcRetreatOverlayUI = NpcRetreatOverlayUI:new();
    self.npcRetreatOverlayUI:initialise();
    self.npcRetreatOverlayUI:addToUIManager();

    self.npcDialogueUI = NpcDialogueUI:new();
    self.npcDialogueUI:initialise();
    self.npcDialogueUI:addToUIManager();
    self.npcDialogueUI:setVisible(false);
end

local function knoxEventToggleSafety(key)
    if key == getCore():getKey("Toggle Safety") then
        if getPlayerSafetyUI(0) then
            getPlayerSafetyUI(0):toggleSafety()
        end
    end
end

Events.OnKeyPressed.Add(knoxEventToggleSafety);