if isClient() then return end;

require "ISBaseObject"

local NPC_PRESETS = "KnoxEventNpcPresets";
local NPC_WEAPONS_KEY = "WEAPONS";
local NPC_BAG_KEY = "BAGS";
local NPC_OUTFITS_KEY = "OUTFITS";
local NPC_CLOTHES_KEY = "CLOTHES";
local NPC_SOLDIER_KEY = "SoldierNpc";

local function addSoldierNpcPreset(_isNewGame)
    local npcPreset = NpcPreset.new();

    local weapons = ArrayList.new();
    weapons:add("AssaultRifle");
    npcPreset:setWeaponsTier1(weapons);

    local bags = ArrayList.new();
    bags:add("Bag_ALICEpack_Army");
    npcPreset:setBags(bags);

    local outfit1 = ArrayList.new("Hat_Army", "Jacket_ArmyCamoGreen",
    "Tshirt_ArmyGreen", "Vest_BulletArmy", "Trousers_ArmyService", "Shoes_ArmyBoots");
    local outfits = ArrayList.new(outfit1);
    npcPreset:addOutfit("Soldier", outfit1);

    npcPreset:setBehaviorTree("SoldierBehaviorTree");

    KnoxEventNpcAPI.instance:addPreset(NPC_SOLDIER_KEY, npcPreset);
end

SoldierPreset = ISBaseObject:derive("SoldierPreset");

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
	o.preset:setBehaviorTree("SoldierBehaviorTree");
	return o
end

Events.OnInitGlobalModData.Add(function() SoldierPreset.instance = SoldierPreset:new(); end)