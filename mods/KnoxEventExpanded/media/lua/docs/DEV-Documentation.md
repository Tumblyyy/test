# Knox Event Expanded - Quest System Documentation

## Overview

The quest system extends the Knox Event Expanded mod by adding structured missions with objectives, rewards, and dialogue. It provides a framework for creating narrative content and gameplay goals for players to pursue.

## File Structure

```
media/lua/
  ├── shared/
  │   └── 04_QuestSystem/
  │       ├── QuestManager.lua         # Core quest handling logic
  │       └── QuestDefinitions.lua     # Quest data definitions
  ├── client/
  │   └── 04_QuestSystem/
  │       ├── QuestDialogueUI.lua      # Quest dialogue interface
  │       ├── QuestEvents.lua          # Event handlers for objectives
  │       ├── QuestJournalUI.lua       # Quest journal interface
  │       └── QuestNpcIntegration.lua  # Integration with NPC system
```

## Core Components

### QuestManager

The central module managing quest state, objectives, and progress.

**Key Functions:**
- `QuestManager.registerQuest(questDef)` - Register a new quest definition
- `QuestManager.startQuest(playerId, questId)` - Start a quest for a player
- `QuestManager.updateObjective(playerId, questId, objectiveId, progress)` - Update objective progress
- `QuestManager.completeQuest(playerId, questId)` - Complete a quest for a player
- `QuestManager.failQuest(playerId, questId)` - Fail a quest for a player
- `QuestManager.hasQuest(playerId, questId)` - Check if a player has an active quest
- `QuestManager.hasCompletedQuest(playerId, questId)` - Check if a player has completed a quest
- `QuestManager.getQuest(questId)` - Get a quest definition
- `QuestManager.getActiveQuest(playerId, questId)` - Get a player's active quest instance
- `QuestManager.getAllActiveQuests(playerId)` - Get all active quests for a player
- `QuestManager.getAllCompletedQuests(playerId)` - Get all completed quests for a player

### Quest Definition Schema

```lua
{
    id = "unique_quest_id",
    title = "Quest Title",
    description = "Quest description text.",
    type = "main|side|faction|daily|event",
    difficulty = 1-4, -- EASY, MEDIUM, HARD, VERY_HARD
    giver = "npc_type_key",
    minLevel = 0, -- Minimum player level required
    
    -- Quest objectives array
    objectives = {
        {
            id = "objective_id",
            description = "Objective description",
            count = 5, -- Required count to complete
            type = "item|kill|escort|protect", -- Objective type
            items = {"Base.ItemType1", "Base.ItemType2"}, -- For item objectives
            targetType = "zombie|bandit|military", -- For kill objectives
            targetId = "specific_npc_id", -- For escort/protect objectives
            duration = 24, -- For timed objectives (hours)
        },
        -- Additional objectives...
    },
    
    -- Quest rewards array
    rewards = {
        {
            type = "item",
            item = "Base.ItemType",
            count = 1
        },
        {
            type = "xp",
            skill = "Aiming", -- PZ skill name
            amount = 10
        },
        -- Additional rewards...
    },
    
    -- Quest dialogue text
    dialogue = {
        offer = "Initial quest offer text.",
        accept = "Text when player accepts quest.",
        decline = "Text when player declines quest.",
        active = "Text when checking on quest progress.",
        complete = "Text when player completes quest."
    },
    
    -- Optional callback functions
    onStart = function(player, questInstance) -- Custom logic when quest starts
    end,
    onComplete = function(player, questInstance) -- Custom logic when quest completes
    end,
    onFail = function(player, questInstance) -- Custom logic when quest fails
    end
}
```

## User Interface Components

### QuestDialogueUI

Handles quest dialogues with NPCs.

**Key Functions:**
- `QuestDialogueUI.showQuestDialogue(npc, npcId, questId, state)` - Show quest dialogue UI for a specific NPC and quest

### QuestJournalUI

Provides a journal interface for tracking quests.

**Key Functions:**
- `QuestJournalUI.createUI()` - Create the journal UI instance
- `QuestJournalUI:toggleVisibility()` - Toggle journal visibility

**Controls:**
- `J` key - Toggle quest journal visibility

## Event Handling

### QuestEvents

Handles game events that trigger quest objective updates.

**Tracked Events:**
- `OnZombieDead` - For kill objectives
- `OnItemPickup` - For item collection objectives
- `Events.EveryTenMinutes` - Periodic check for item objectives

**Custom Events:**
- `QuestEvents.OnNPCReachedDestination(npcId, targetLocation)` - For escort objectives
- `QuestEvents.OnNPCSurvivalCheck(npcId, duration)` - For protection objectives

## NPC Integration

### QuestNpcIntegration

Connects the quest system with the existing NPC system.

**Key Components:**
- NPC type mapping to quest giver types
- Context menu integration for quest interactions
- Custom item creation for quest objectives

**Quest Giver Types:**
- `random_survivor` → "survivor", "civilian", "scavenger"
- `military_survivor` → "military", "soldier", "ranger"
- `wounded_military` → "wounded_military", "injured_military"

## Creating New Quests

1. Create a quest definition object following the schema
2. Register the quest using `QuestManager.registerQuest(questDef)`
3. Ensure NPC types are mapped to the quest giver type
4. Create any custom items needed for the quest
5. Add the quest to appropriate quest chains if needed

## Example Quest Definition

```lua
QuestManager.registerQuest({
    id = "quest_survivor_supply_run",
    title = "Survivor Supply Run",
    description = "Collect essential supplies for a survivor camp.",
    type = "side",
    difficulty = 1, -- EASY
    giver = "random_survivor",
    minLevel = 0,
    
    objectives = {
        {
            id = "collect_food",
            description = "Collect canned food",
            count = 5,
            type = "item",
            items = {"Base.TinnedBeans", "Base.CannedCorn", "Base.CannedCarrots", 
                    "Base.CannedTomato", "Base.CannedPotato"}
        },
        {
            id = "collect_medicine",
            description = "Collect medicine",
            count = 3,
            type = "item",
            items = {"Base.PillsAntiDep", "Base.PillsBeta", "Base.PillsVitamins", 
                    "Base.Bandage", "Base.Bandaid"}
        }
    },
    
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
    
    dialogue = {
        offer = "We're running low on supplies at camp. Could you gather some essentials for us?",
        accept = "Thank you! We really need food and medicine. Bring back whatever you can find.",
        decline = "I understand. It's dangerous out there. Maybe someone else can help us.",
        active = "Did you find those supplies yet? We're counting on you.",
        complete = "These supplies will help us survive another week. Here, take this as a token of our gratitude."
    }
})
```

## Common Item IDs Reference

For a complete list of item IDs, refer to: https://pzwiki.net/wiki/PZwiki:Item_list

Item IDs always follow the format `Base.ItemName`. Common items used in quests:

### Food Items
- `Base.TinnedBeans` - Canned beans
- `Base.CannedCorn` - Canned corn
- `Base.CannedCarrots` - Canned carrots
- `Base.CannedTomato` - Canned tomatoes
- `Base.CannedPotato` - Canned potatoes
- `Base.CannedSardines` - Canned sardines
- `Base.CannedBolognese` - Canned bolognese
- `Base.CannedChili` - Canned chili
- `Base.CannedCornedBeef` - Canned corned beef
- `Base.CannedMushroomSoup` - Mushroom soup

### Medical Items
- `Base.Bandage` - Bandage
- `Base.Bandaid` - Bandage
- `Base.PillsAntiDep` - Antidepressants
- `Base.PillsBeta` - Beta blockers
- `Base.PillsVitamins` - Vitamins
- `Base.Disinfectant` - Disinfectant
- `Base.AlcoholWipes` - Alcohol wipes
- `Base.Antibiotics` - Antibiotics
- `Base.PainkillerTablets` - Painkillers
- `Base.SutureNeedle` - Suture needle

### Weapons
- `Base.Pistol` - Pistol
- `Base.Shotgun` - Shotgun
- `Base.AssaultRifle` - Assault rifle
- `Base.HuntingRifle` - Hunting rifle
- `Base.BaseballBat` - Baseball bat
- `Base.Crowbar` - Crowbar
- `Base.Axe` - Axe
- `Base.Sledgehammer` - Sledgehammer
- `Base.Machete` - Machete
- `Base.KitchenKnife` - Kitchen knife

### Ammunition
- `Base.Bullets9mm` - 9mm bullets
- `Base.Bullets45` - .45 bullets
- `Base.223Bullets` - .223 bullets
- `Base.308Bullets` - .308 bullets
- `Base.ShotgunShells` - Shotgun shells

### Custom Items
The mod adds custom items for quest objectives:
- `KnoxEventExpanded.IntelDocuments` - Intelligence documents for military quests

## Debugging

To debug quest issues:
1. Check console for error messages
2. Verify quest and objective IDs match exactly
3. Ensure NPC types are correctly mapped to quest giver types
4. Test objectives by manually running:
   ```lua
   QuestManager.updateObjective(playerId, questId, objectiveId, progress)
   ```
5. Check quest state with:
   ```lua
   local quest = QuestManager.getActiveQuest(playerId, questId)
   print(serpent.block(quest)) -- Requires serpent lib
   ```

## Best Practices

1. Keep quest IDs unique and descriptive (use prefix like `quest_`)
2. Test all dialogue paths before releasing a quest
3. Ensure all item IDs exist in the game or are custom-defined
4. Provide balanced rewards appropriate to quest difficulty
5. Connect quests to form meaningful chains or storylines
6. Use the `onStart` and `onComplete` callbacks for special effects or spawning 