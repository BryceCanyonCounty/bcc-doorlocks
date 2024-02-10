Config = {}

Config.defaultlang = 'en_lang' --set your language here current supported languages: "en_lang" = english
Config.DevMode = true --false on live server

Config.CreateDoorCommand = 'createDoor' --command to create door
Config.DeleteDoorCommand = 'deleteDoor' --command to delete door

Config.DoorRadius = 1.5 -- Maximum Distance from Door to Operate

---------- Admin Configuration (Anyone listed here will be able to create and delete doors!) -----------
Config.AdminGroup = 'admin'

Config.LockPicking = {
    allowlockpicking = true, --If true players will be able to lockpick doors
    minigameSettings = {
        MaxAttemptsPerLock = 3,
        lockpickitem = 'lockpick',
        difficulty = 50,
        hintdelay = 500,
    },
}