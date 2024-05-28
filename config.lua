Config = {}

Config.defaultlang = 'en_lang' --set your language here current supported languages: "en_lang" = english
Config.DevMode = false --false on live server

Config.CreateDoorCommand = 'createDoor' --command to create door
Config.DeleteDoorCommand = 'deleteDoor' --command to delete door

Config.DoorRadius = 1.5 -- Maximum Distance from Door to Operate

---------- Admin Configuration (Anyone listed here will be able to create and delete doors!) -----------
Config.AdminSteamIds = {
    {
        steamid = 'steam:11000010401e04f', --insert players steam id
    }, --to add more just copy this table paste and change id
}

Config.LockPicking = {
    bcc_minigames = false,
    rsd_lockpick = true,

    allowlockpicking = true, --If true players will be able to lockpick doors
    minigameSettings = {
        MaxAttemptsPerLock = 3, -- only bcc_minigames
        lockpickitem = 'lockpick',
        difficulty = 50, -- only bcc_minigames
        hintdelay = 500, -- only bcc_minigames
    },
}
Config = {}

Config.defaultlang = 'en_lang'          --set your language here current supported languages: "en_lang" = english
Config.DevMode = false                  --false on live server

Config.CreateDoorCommand = 'createDoor' --command to create door
Config.DeleteDoorCommand = 'deleteDoor' --command to delete door

Config.DoorRadius = 1.5                 -- Maximum Distance from Door to Operate

---------- Admin Configuration (Anyone listed here will be able to create and delete doors!) -----------
Config.AdminSteamIds = {
    {
        steamid = 'steam:11000010401e04f', --insert players steam id
    },                                     --to add more just copy this table paste and change id
}

Config.LockPicking = {
    bcc_minigames = false,
    rsd_lockpick = true,

    allowlockpicking = true,    --If true players will be able to lockpick doors
    minigameSettings = {
        MaxAttemptsPerLock = 3, -- only bcc_minigames
        lockpickitem = 'lockpick',
        difficulty = 50,        -- only bcc_minigames
        hintdelay = 500,        -- only bcc_minigames
    },
}
