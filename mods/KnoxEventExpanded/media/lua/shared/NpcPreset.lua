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
	return self
end

function NpcPreset:setBehaviorTree(behaviorTree)
    self.behaviorTree = behaviorTree
end

return NpcPreset