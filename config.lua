Config = {}

Config.defaultlang = 'en_lang' -- Set your language here current supported languages: "en_lang" = english
Config.DevMode = false -- false on live server

Config.CreateDoorCommand = 'createDoor' -- Command to create door
Config.DeleteDoorCommand = 'deleteDoor' -- Command to delete door

Config.DoorRadius = 1.5 -- Maximum Distance from Door to Operate

---------- Admin Configuration (Anyone listed here will be able to create and delete doors!) ----------
Config.AdminSteamIds = {
    {
        steamid = 'steam:12004500000a00b', -- Insert players steam id
    }, --to add more just copy this table paste and change id
}

Config.LockPicking = {
    bcc_minigames = true,
    rsd_lockpick = false,

    allowlockpicking = true, -- If true players will be able to lockpick doors
    minigameSettings = {
        MaxAttemptsPerLock = 3, -- Only bcc_minigames
        lockpickitem = 'lockpick',
        difficulty = 50, -- Only bcc_minigames
        hintdelay = 500, -- Only bcc_minigames
    },
}
