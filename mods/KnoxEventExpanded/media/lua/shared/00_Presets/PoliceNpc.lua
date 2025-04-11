if isClient() then return end;

require "ISBaseObject"

local NPC_PRESETS = "KnoxEventNpcPresets";
local NPC_WEAPONS_KEY = "WEAPONS";
local NPC_BAG_KEY = "BAGS";
local NPC_OUTFITS_KEY = "OUTFITS";
local NPC_CLOTHES_KEY = "CLOTHES";
local NPC_POLICE_KEY = "PoliceNpc";

local function addPoliceNpcPreset(_isNewGame)
    local npcPreset = NpcPreset.new();

    local weapons = ArrayList.new();
    npcPreset:setWeaponsTier1(weapons);
    npcPreset:setWeaponsTier2(weapons);
    npcPreset:setWeaponsTier3(weapons);

    local bags = ArrayList.new();
    npcPreset:setBags(bags);

    local citycop = ArrayList.new("Pistol2", "Shirt_PoliceBlue", "Vest_BulletPolice", "HolsterSimple", "Trousers_Police", "Shoes_BlackBoots");
    npcPreset:addOutfit("CityCop", citycop);

    local deputy = ArrayList.new("Revolver_Long", "Hat_Police_Grey", "Shirt_PoliceGrey", "Jacket_Police", "HolsterSimple", "Trousers_PoliceGrey", "Shoes_BlackBoots");
    npcPreset:addOutfit("Deputy", deputy);

    local trooper = ArrayList.new("Revolver_Long", "Hat_Police", "Shirt_PoliceBlue", "HolsterSimple", "Trousers_Police", "Shoes_BlackBoots");
    npcPreset:addOutfit("Trooper", trooper);

    local clothes = ArrayList.new();
    npcPreset:setMaleClothes(clothes);
    npcPreset:setFemaleClothes(clothes);

    npcPreset:setBehaviorTree("PoliceBehaviorTree");

    KnoxEventNpcAPI.instance:addPreset(NPC_POLICE_KEY, npcPreset);
end

PolicePreset = ISBaseObject:derive("PolicePreset");

function PolicePreset:dressNpc(npc)
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
	return o
end

Events.OnInitGlobalModData.Add(function() PolicePreset.instance = PolicePreset:new(); end)