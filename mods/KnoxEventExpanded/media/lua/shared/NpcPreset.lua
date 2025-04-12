lua
if isClient() then return end

local NpcPreset = {}
NpcPreset.__index = NpcPreset

function NpcPreset.new(name, faction, partyID)
	local self = setmetatable({}, NpcPreset)
	self.name = name
	self.behaviorTree = nil
	self.faction = faction
	self.partyID = partyID
	self.quests = {}
	self.isRecruitable = false
	self.loyalty = 100
	self.skills = {}
	self.inventory = {}
	self.needs = {}
	self.presetClothes = {}  -- Initialize presetClothes
	return self
end

function NpcPreset:setBehaviorTree(behaviorTree)
    self.behaviorTree = behaviorTree
end

function NpcPreset:dressNpc(npc)
	<CODE_BLOCK>
    if not npc then return end -- Check if npc is not nil
    if not self.presetClothes or next(self.presetClothes) == nil then
        return  -- Return if presetClothes is empty or nil
    end

    for slot, item in pairs(self.presetClothes) do
        local itemType = ItemType.FromFullName(item)
        if itemType then
            npc:getInventory():equipItem(itemType.module, itemType.name, slot)
        end
    end
	</CODE_BLOCK>
end

return NpcPreset