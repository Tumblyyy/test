if isClient() or isServer() then return end

require "ISUI/Maps/ISWorldMapSymbolTool"

WorldMapWaypointTool = ISWorldMapSymbolTool:derive("WorldMapWaypointTool")

function WorldMapWaypointTool:new(symbolsUI)
       local o = ISWorldMapSymbolTool.new(self, symbolsUI)
       o.dotTex = "SolidCircle";
       o.scale = 2;
       o.fill = 1
       return o
end

function WorldMapWaypointTool:addWaypoint(worldX, worldY)
       local tex = self.lineTex;
       if self.symbolsUI.selectedSymbol then
               tex = self.symbolsUI.selectedSymbol.tex;
       end

       local textureSymbol = self.symbolsAPI:addTexture(tex, worldX, worldY)
       local col = self.symbolsUI.currentColor;
       textureSymbol:setRGBA(col:getR(), col:getG(), col:getB(), 1.0);
       textureSymbol:setAnchor(0.5, 0.5)
       textureSymbol:setScale(ISMap.SCALE * self.scale / 10)
end

function WorldMapWaypointTool:removeWaypoint(x, y)
       local index = self.symbolsAPI:hitTest(x, y)
       if index ~= -1 then
               self.symbolsAPI:removeSymbolByIndex(index)
       end
end

ISWorldMapSymbols.initTools_old = ISWorldMapSymbols.initTools;
ISWorldMapSymbols.initTools = function(self)
       self:initTools_old();
       self.tools.WaypointTool = WorldMapWaypointTool:new(self);
end

local oldWaypointsList = {}
local waypointsList = {}
local waypointsToAdd = {}

ISWorldMap.render_old = ISWorldMap.render
ISWorldMap.render = function(self)
        self:render_old();
        if #waypointsToAdd > 0 then
                for i=1,#waypointsToAdd do
                        table.insert(waypointsList, waypointsToAdd[i]);
                        local x = waypointsToAdd[i]["x"];
                        local y = waypointsToAdd[i]["y"];
                        self.symbolsUI.tools.WaypointTool:addWaypoint(x,y);
                end
                table.wipe(waypointsToAdd);
                oldWaypointsList = waypointsList;
        elseif oldWaypointsList ~= waypointsList then
                for k,v in pairs(oldWaypointsList) do
                       local x = v["x"]
                       local y = v["y"]
                       self.symbolsUI.tools.WaypointTool:removeWaypoint(x,y);
                end
                for k,v in pairs(waypointsList) do
                       local x = v["x"]
                       local y = v["y"]
                       self.symbolsUI.tools.WaypointTool:addWaypoint(x,y);
                end
                oldWaypointsList = waypointsList;
       end
end

local function waypointCommandHandler(_module, _command, _data)
    if _module == "KnoxEventDebug" then
        if _command == "GetWaypoints" then
                if _data ~= nil then
                        oldWaypointsList = waypointsList
                        waypointsList = _data
                end
        elseif _command == "AddWaypoint" then
                if _data ~= nil then
                        local x = tonumber(_data["wx"]);
                        local y = tonumber(_data["wy"]);
                        local wp = {};
                        wp["x"] = x;
                        wp["y"] = y;
                        table.insert(waypointsToAdd, wp);
                end
        end
    end
end

if isClient() and isDebugEnabled() then
    Events.OnServerCommand.Add(waypointCommandHandler)
end