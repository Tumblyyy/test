-- Quest Definitions for Knox Event Expanded
-- Contains definitions for available quests

require "04_QuestSystem/QuestManager"

-- Quest types/categories
local QUEST_TYPE = {
    MAIN = "main",        -- Main storyline quests
    SIDE = "side",        -- Optional side quests
    FACTION = "faction",  -- Faction reputation quests
    DAILY = "daily",      -- Repeatable daily quests
    EVENT = "event"       -- Special event quests
}

-- Quest difficulty levels
local QUEST_DIFFICULTY = {
    EASY = 1,
    MEDIUM = 2,
    HARD = 3,
    VERY_HARD = 4
}

-- Register basic quests
local function RegisterQuestDefinitions()
    -- Survivor Supply Run quest
    QuestManager.registerQuest({
        id = "quest_survivor_supply_run",
        title = "Survivor Supply Run",
        description = "Collect essential supplies for a survivor camp.",
        type = QUEST_TYPE.SIDE,
        difficulty = QUEST_DIFFICULTY.EASY,
        giver = "random_survivor", -- NPC type that can give this quest
        minLevel = 0, -- Player minimum level to get this quest
        
        -- Quest objectives
        objectives = {
            {
                id = "collect_food",
                description = "Collect canned food",
                count = 5,
                type = "item",
                items = {"Base.TinnedBeans", "Base.CannedCorn", "Base.CannedCarrots", "Base.CannedTomato", "Base.CannedPotato"}
            },
            {
                id = "collect_medicine",
                description = "Collect medicine",
                count = 3,
                type = "item",
                items = {"Base.PillsAntiDep", "Base.PillsBeta", "Base.PillsVitamins", "Base.Bandage", "Base.Bandaid"}
            }
        },
        
        -- Quest rewards
        rewards = {
            {
                type = "item",
                item = "Base.Pistol",
                count = 1
            },
            {
                type = "xp",
                skill = "Aiming",
                amount = 10
            }
        },
        
        -- Quest dialogue
        dialogue = {
            offer = "We're running low on supplies at camp. Could you gather some essentials for us?",
            accept = "Thank you! We really need food and medicine. Bring back whatever you can find.",
            decline = "I understand. It's dangerous out there. Maybe someone else can help us.",
            active = "Did you find those supplies yet? We're counting on you.",
            complete = "These supplies will help us survive another week. Here, take this as a token of our gratitude."
        },
        
        -- Quest callback functions (optional)
        onStart = function(player, questInstance)
            -- Custom logic when quest is started
            player:Say("I'll find those supplies.")
        end,
        
        onComplete = function(player, questInstance)
            -- Custom logic when quest is completed
            player:Say("I've got the supplies you needed.")
        end
    })
    
    -- Bandit Hideout quest
    QuestManager.registerQuest({
        id = "quest_bandit_hideout",
        title = "Clearing the Bandit Hideout",
        description = "Clear out a nearby bandit hideout that's been threatening survivors.",
        type = QUEST_TYPE.SIDE,
        difficulty = QUEST_DIFFICULTY.MEDIUM,
        giver = "military_survivor",
        minLevel = 3,
        
        -- Quest objectives
        objectives = {
            {
                id = "kill_bandits",
                description = "Eliminate bandits",
                count = 5,
                type = "kill",
                targetType = "bandit"
            },
            {
                id = "retrieve_intel",
                description = "Retrieve intelligence documents",
                count = 1,
                type = "item",
                items = {"KnoxEventExpanded.IntelDocuments"}
            }
        },
        
        -- Quest rewards
        rewards = {
            {
                type = "item",
                item = "Base.AssaultRifle",
                count = 1
            },
            {
                type = "xp",
                skill = "Aiming",
                amount = 25
            }
        },
        
        -- Quest dialogue
        dialogue = {
            offer = "We've located a group of bandits causing trouble for survivors nearby. Can you help clear them out?",
            accept = "Excellent. Eliminate the bandits and retrieve any intelligence documents you find.",
            decline = "Understood. These bandits are dangerous, so I don't blame you.",
            active = "Have you cleared out those bandits yet? They continue to terrorize the area.",
            complete = "Good work, soldier. The area should be safer now, and these documents will help us track more of their operations."
        }
    })
    
    -- Military Escort quest
    QuestManager.registerQuest({
        id = "quest_military_escort",
        title = "Escort the Military Survivor",
        description = "Escort a wounded military survivor back to their base.",
        type = QUEST_TYPE.MAIN,
        difficulty = QUEST_DIFFICULTY.HARD,
        giver = "wounded_military",
        minLevel = 5,
        
        -- Quest objectives
        objectives = {
            {
                id = "escort_to_base",
                description = "Escort the survivor to base",
                count = 1,
                type = "escort",
                targetId = "wounded_military_survivor"
            },
            {
                id = "protect_from_zombies",
                description = "Protect from zombie attacks",
                count = 1,
                type = "protect"
            }
        },
        
        -- Quest rewards
        rewards = {
            {
                type = "item",
                item = "Base.Shotgun",
                count = 1
            },
            {
                type = "item",
                item = "Base.ShotgunShells",
                count = 10
            },
            {
                type = "xp",
                skill = "Aiming",
                amount = 50
            }
        },
        
        -- Quest dialogue
        dialogue = {
            offer = "I've been separated from my squad and wounded. Can you help me get back to our base?",
            accept = "Thank you. I can't move very fast with this leg, so we'll need to be careful.",
            decline = "I understand. I'll try to make it on my own.",
            active = "We need to keep moving. The base isn't far now.",
            complete = "Thanks for getting me back safely. The commander will want to speak with you."
        }
    })
end

-- Register quests when the game starts
Events.OnGameBoot.Add(RegisterQuestDefinitions) 