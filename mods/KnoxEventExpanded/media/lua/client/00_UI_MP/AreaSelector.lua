if not isClient() or isServer() then return end

--***********************************************************
--**                    THE INDIE STONE                    **
--**				    Author: Aiteron				       **
--***********************************************************

require "ISUI/ISPanelJoypad"

AreaSelector = ISPanelJoypad:derive("AreaSelector");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function AreaSelector:initialise()
    ISPanelJoypad.initialise(self);

    local fontHgt = FONT_HGT_SMALL
    local buttonWid1 = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_KnoxEvent_Npc_AreaSelect")) + 12;
    local buttonWid2 = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_KnoxEvent_Npc_AreaRemove")) + 12;
    local buttonWid3 = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_KnoxEvent_Npc_AreaClose")) + 12;
    local buttonWid = math.max(math.max(buttonWid1, buttonWid2, buttonWid3), 100);
    local buttonHgt = math.max(fontHgt + 6, 25);
    local padBottom = 10;

    self.select = ISButton:new((self:getWidth() / 6) - buttonWid/2, self:getHeight() - padBottom - buttonHgt, buttonWid, buttonHgt, "Select area", self, AreaSelector.onClick);
    self.select.internal = "SELECT";
    self.select:initialise();
    self.select:instantiate();
    self.select.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.select);

    self.set = ISButton:new((self:getWidth() / 2) - buttonWid/2, self:getHeight() - padBottom - buttonHgt, buttonWid, buttonHgt, "Set", self, AreaSelector.onClick);
    self.set.internal = "SET";
    self.set:initialise();
    self.set:instantiate();
    self.set.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.set);

    self.close = ISButton:new((self:getWidth() / 6)*5 - buttonWid/2, self:getHeight() - padBottom - buttonHgt, buttonWid, buttonHgt, "Close", self, AreaSelector.onClick);
    self.close.internal = "CLOSE";
    self.close:initialise();
    self.close:instantiate();
    self.close.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.close);
end

function AreaSelector:destroy()
    self:setVisible(false);
    self:removeFromUIManager();
end

function AreaSelector:onClick(button)
    if button.internal == "SELECT" then
        self.selectEnd = false
        self.startPos = nil
        self.endPos = nil
        --self.zPos = self.player:getZ()
        self.zPos = 0
        self.selectStart = true
    end
    if button.internal == "SET" then
        if self.startPos ~= nil and self.endPos ~= nil then
            if self.type == "CHOPTREES" then
                setNpcChopTreesArea(self.startPos.x, self.startPos.y, self.endPos.x, self.endPos.y);
            elseif self.type == "CORPSECLEAR" then
                setNpcCorpseClearArea(self.startPos.x, self.startPos.y, self.endPos.x, self.endPos.y);
            elseif self.type == "CORPSEDUMP" then
                setNpcCorpseDumpArea(self.startPos.x, self.startPos.y, self.endPos.x, self.endPos.y);
            elseif self.type == "GUARD" then
                setNpcGuardArea(self.startPos.x, self.startPos.y, self.endPos.x, self.endPos.y);
            end
        end
    end
    if button.internal == "CLOSE" then
        self:destroy();
        return;
    end
end

function AreaSelector:titleBarHeight()
    return 16
end

function AreaSelector:prerender()
    self.backgroundColor.a = 0.8

    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);

    local th = self:titleBarHeight()
    self:drawTextureScaled(self.titlebarbkg, 2, 1, self:getWidth() - 4, th - 2, 1, 1, 1, 1);

    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    self:drawTextCentre("Select ".. self.title .. " Area", self:getWidth() / 2, 20, 1, 1, 1, 1, UIFont.NewLarge);

    local x1Text = "x1: ";
    if self.startPos ~= nil then
        x1Text = x1Text .. tostring(self.startPos.x);
    end

    local y1Text = "y1: ";
    if self.startPos ~= nil then
        y1Text = y1Text .. tostring(self.startPos.y);
    end

    local x2Text = "x2: ";
    if self.endPos ~= nil then
        x2Text = x2Text .. tostring(self.endPos.x);
    end

    local y2Text = "y1: ";
    if self.endPos ~= nil then
        y2Text = y2Text .. tostring(self.endPos.y);
    end

    self:drawText(x1Text, self:getWidth() / 3, 70, 1, 1, 1, 1, UIFont.Small);
    self:drawText(y1Text, 2 * self:getWidth() / 3, 70, 1, 1, 1, 1, UIFont.Small);

    self:drawText(x2Text, self:getWidth() / 3, 90, 1, 1, 1, 1, UIFont.Small);
    self:drawText(y2Text, 2 * self:getWidth() / 3, 90, 1, 1, 1, 1, UIFont.Small);
end

function AreaSelector:render()
    if self.selectStart then
        local xx, yy = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), self.zPos)
        local sq = getCell():getGridSquare(math.floor(xx), math.floor(yy), self.zPos)
        if sq and sq:getFloor() then sq:getFloor():setHighlighted(true) end
    elseif self.selectEnd then
        local xx, yy = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), self.zPos)
        xx = math.floor(xx)
        yy = math.floor(yy)
        local cell = getCell()
        local x1 = math.min(xx, self.startPos.x)
        local x2 = math.max(xx, self.startPos.x)
        local y1 = math.min(yy, self.startPos.y)
        local y2 = math.max(yy, self.startPos.y)

        for x = x1, x2 do
            for y = y1, y2 do
                local sq = cell:getGridSquare(x, y, self.zPos)
                if sq and sq:getFloor() then sq:getFloor():setHighlighted(true) end
            end
        end
    elseif self.startPos ~= nil and self.endPos ~= nil then
        local cell = getCell()
        local x1 = math.min(self.startPos.x, self.endPos.x)
        local x2 = math.max(self.startPos.x, self.endPos.x)
        local y1 = math.min(self.startPos.y, self.endPos.y)
        local y2 = math.max(self.startPos.y, self.endPos.y)
        for x = x1, x2 do
            for y = y1, y2 do
                local sq = cell:getGridSquare(x, y, self.zPos)
                if sq and sq:getFloor() then sq:getFloor():setHighlighted(true) end
            end
        end
    end
end

function AreaSelector:onMouseMove(dx, dy)
    self.mouseOver = true
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

function AreaSelector:onMouseMoveOutside(dx, dy)
    self.mouseOver = false
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

function AreaSelector:onMouseDown(x, y)
    if not self:getIsVisible() then
        return
    end
    self.downX = x
    self.downY = y
    self.moving = true
    self:bringToTop()
end

function AreaSelector:onMouseUp(x, y)
    if not self:getIsVisible() then
        return;
    end
    self.moving = false
    if ISMouseDrag.tabPanel then
        ISMouseDrag.tabPanel:onMouseUp(x,y)
    end
    ISMouseDrag.dragView = nil
end

function AreaSelector:onMouseUpOutside(x, y)
    if not self:getIsVisible() then
        return
    end
    self.moving = false
    ISMouseDrag.dragView = nil
end

function AreaSelector:onMouseDownOutside(x, y)
    local xx, yy = ISCoordConversion.ToWorld(getMouseXScaled(), getMouseYScaled(), self.zPos)
    if self.selectStart then
        self.startPos = { x = math.floor(xx), y = math.floor(yy) }
        self.selectStart = false
        self.selectEnd = true
    elseif self.selectEnd then
        self.endPos = { x = math.floor(xx), y = math.floor(yy) }
        self.selectEnd = false
    end
end

function AreaSelector:new(x, y, width, height, title)
    local o = ISPanelJoypad:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self

    if y == 0 then
        o.y = o:getMouseY() - (height / 2)
        o:setY(o.y)
    end
    if x == 0 then
        o.x = o:getMouseX() - (width / 2)
        o:setX(o.x)
    end
    o.name = nil;
    o.title = title;
    o.backgroundColor = {r=0, g=0, b=0, a=0.5};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.width = width;
    o.height = height;
    o.anchorLeft = true;
    o.anchorRight = true;
    o.anchorTop = true;
    o.anchorBottom = true;
    o.titlebarbkg = getTexture("media/ui/Panel_TitleBar.png");
    o.numLines = 1
    o.maxLines = 1
    o.multipleLine = false

    o.selectStart = false
    o.selectEnd = false
    o.startPos = nil
    o.endPos = nil
    o.zPos = 0

    return o;
end
