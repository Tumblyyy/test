if isClient() then return end;

require "ISBaseObject"
require "NpcPreset"

SoldierPreset = ISBaseObject:derive("SoldierPreset");

local function addEscortQuest(preset)
    table.insert(preset.quests, "escort")
end

function SoldierPreset:dressNpc(npc)
    local hat = npc:getInventory():AddItem("Hat_Army");
    npc:setWornItem(hat:getBodyLocation(), hat);

    local jacket = npc:getInventory():AddItem("Jacket_ArmyCamoGreen");
    npc:setWornItem(jacket:getBodyLocation(), jacket);

    local shirt = npc:getInventory():AddItem("Tshirt_ArmyGreen");
    npc:setWornItem(shirt:getBodyLocation(), shirt);

    local vest = npc:getInventory():AddItem("Vest_BulletArmy");
    npc:setWornItem(vest:getBodyLocation(), vest);

    local pants = npc:getInventory():AddItem("Trousers_ArmyService");
    npc:setWornItem(pants:getBodyLocation(), pants);

    local belt = npc:getInventory():AddItem("Base.Belt2");
    npc:setWornItem(belt:getBodyLocation(), belt);

    local socks = npc:getInventory():AddItem("Socks_Ankle");
    npc:setWornItem(socks:getBodyLocation(), socks);

    local boots = npc:getInventory():AddItem("Shoes_ArmyBoots");
    npc:setWornItem(boots:getBodyLocation(), boots);

    local watch = npc:getInventory():AddItem("WristWatch_Left_ClassicMilitary");
    npc:setWornItem(watch:getBodyLocation(), watch);

    local backpack = npc:getInventory():AddItem("Bag_ALICEpack_Army");
    npc:setClothingItem_Back(nil);
	npc:setClothingItem_Back(backpack);
    local gun = npc:getInventory():AddItem("AssaultRifle");
	npc:setPrimaryHandItem(gun);
	npc:setSecondaryHandItem(gun);
    if gun:getMagazineType() == nil then
       gun:setCurrentAmmoCount(gun:getMaxAmmo());
    else
       gun:setCurrentAmmoCount(gun:getMaxAmmo());
       gun:setContainsClip(true);
    end
end

function SoldierPreset:dressNpcWithOutfit(npc, outfit)
    self:dress(npc);
end

function SoldierPreset:new()
    local o = {}
	setmetatable(o, self)
	self.__index = self
    o.preset = NpcPreset.new("SoldierNpc", o);
    o.preset.faction = "Soldiers";
    o.preset.partyID = "SoldierNpc";
    o.preset:setBehaviorTree("SoldierBehaviorTree");
    addEscortQuest(o.preset)
	return o
end

Events.OnInitGlobalModData.Add(function() SoldierPreset.instance = SoldierPreset:new(); end)