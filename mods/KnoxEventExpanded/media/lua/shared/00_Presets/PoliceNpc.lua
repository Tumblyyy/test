if isClient() then return end;

require "ISBaseObject"
require "NpcPreset"

PolicePreset = ISBaseObject:derive("PolicePreset");

function PolicePreset:dressNpc(npc)
    -- TODO: remove this function and use outfits in NpcPreset
    local random = ZombRand(3);
    if random == 0 then
        self:dressNpcWithOutfit(npc, "CityCop");
    elseif random == 1 then
        self:dressNpcWithOutfit(npc, "Deputy");
    else
        self:dressNpcWithOutfit(npc, "Trooper");
    end
end

function PolicePreset:dressNpcWithOutfit(npc, outfit)
    local boots = npc:getInventory():AddItem("Shoes_BlackBoots");
    npc:setWornItem(boots:getBodyLocation(), boots);

    local holster = npc:getInventory():AddItem("HolsterSimple");
    npc:setWornItem(holster:getBodyLocation(), holster);

    local socks = npc:getInventory():AddItem("Socks_Ankle");
    npc:setWornItem(socks:getBodyLocation(), socks);

    if outfit == "CityCop" then
        local shirt = npc:getInventory():AddItem("Shirt_PoliceBlue");
        npc:setWornItem(shirt:getBodyLocation(), shirt);

        local vest = npc:getInventory():AddItem("Vest_BulletPolice");
        npc:setWornItem(vest:getBodyLocation(), vest);

        local trousers = npc:getInventory():AddItem("Trousers_Police");
        npc:setWornItem(trousers:getBodyLocation(), trousers);

        local gun = npc:getInventory():AddItem("Pistol2");
	    npc:setPrimaryHandItem(gun);
	    npc:setSecondaryHandItem(gun);
    elseif outfit == "Deputy" then
        local hat = npc:getInventory():AddItem("Hat_Police_Grey");
        npc:setWornItem(hat:getBodyLocation(), hat);

        local shirt = npc:getInventory():AddItem("Shirt_PoliceGrey");
        npc:setWornItem(shirt:getBodyLocation(), shirt);

        local jacket = npc:getInventory():AddItem("Jacket_Police");
        npc:setWornItem(jacket:getBodyLocation(), jacket);

        local trousers = npc:getInventory():AddItem("Trousers_PoliceGrey");
        npc:setWornItem(trousers:getBodyLocation(), trousers);

        -- socks?

        local gun = npc:getInventory():AddItem("Revolver_Long");
	    npc:setPrimaryHandItem(gun);
	    npc:setSecondaryHandItem(gun);
    elseif outfit == "Trooper" then
        local hat = npc:getInventory():AddItem("Hat_Police");
        npc:setWornItem(hat:getBodyLocation(), hat);

        local shirt = npc:getInventory():AddItem("Shirt_PoliceBlue");
        npc:setWornItem(shirt:getBodyLocation(), shirt);

        local trousers = npc:getInventory():AddItem("Trousers_Police");
        npc:setWornItem(trousers:getBodyLocation(), trousers);

        -- socks?

        local gun = npc:getInventory():AddItem("Revolver_Long");
        npc:setPrimaryHandItem(gun);
        npc:setSecondaryHandItem(gun);
    end
end

function PolicePreset:new()
    local o = {}
	setmetatable(o, self)
	self.__index = self
    o.preset = NpcPreset.new("PoliceNpc", o);
	o.preset:setBehaviorTree("PoliceBehaviorTree");
    o.preset.faction = "Police"; -- Set faction
    o.preset.partyID = "PoliceNpc"; -- Set partyID
    o.preset.quests = {"raid"}; -- Added raid quest
	return o
end

Events.OnInitGlobalModData.Add(function() PolicePreset.instance = PolicePreset:new(); end)