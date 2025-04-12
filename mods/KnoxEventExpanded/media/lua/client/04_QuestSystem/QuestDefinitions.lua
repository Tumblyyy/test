lua
-- Quest Definitions

-- Example Quest
QuestDefinitions["TutorialQuest"] = {
    title = "Tutorial Quest",
    dialogue = {
        offer = "Welcome to the Tutorial Quest!",
        active = "You are doing great!",
        complete = "You completed the tutorial!"
    },
    objectives = {
        {
            type = "kill",
            npcId = "Zombie"
        },
        {
            type = "item",
            itemId = "Screwdriver"
        },
        {
            type = "location",
            location = { x = getSpecificPlayer(0):getX() + 50, y = getSpecificPlayer(0):getY() + 50 }
        }
    }
}

QuestDefinitions["ItemQuest"] = {
    title = "Item Quest",
    dialogue = {
        offer = "Can you find me an Item?",
        active = "Please hurry!",
        complete = "Thank you!"
    },
    objectives = {
        {
            type = "item",
            itemId = "Screwdriver"
        }
    }
}

QuestDefinitions["ZombieQuest"] = {
    title = "Zombie Quest",
    dialogue = {
        offer = "Can you kill this zombie?",
        active = "He is still alive!",
        complete = "You did it!"
    },
    objectives = {
        {
            type = "kill",
            npcId = "Zombie"
        }
    }
}

QuestDefinitions["LocationQuest"] = {
    title = "Location Quest",
    dialogue = {
        offer = "Go to this location",
        active = "You are close!",
        complete = "Great job!"
    },
    objectives = {
        {
            type = "location",
            location = { x = getSpecificPlayer(0):getX() + 50, y = getSpecificPlayer(0):getY() + 50 }
        }
    }
}
-- Escort Quest
QuestDefinitions["Escort the survivor"] = {
    title = "Escort the survivor",
    dialogue = {
        offer = "Please, help me reach the safe location",
        active = "You are doing great!",
        complete = "Thank you very much!"
    },
    objectives = {
        {
            type = "escort",
            location = { x = getSpecificPlayer(0):getX() + 50, y = getSpecificPlayer(0):getY() + 50 }
        }
    }
}

-- Protection Quest
QuestDefinitions["Protect the survivor"] = {
    title = "Protect the survivor",
    dialogue = {
        offer = "I need your protection!",
        active = "Please be careful",
        complete = "I am safe now. Thank you!"
    },
    objectives = {
        {
            type = "protect"
        }
    }
}
