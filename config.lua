Config = {}

Config.defaultlang = 'en_lang'

---------- Admin Configuration (Anyone listed here will be able to create and delete doors!) -----------
Config.AdminSteamIds = {
    {
        steamid = 'steam:11000013707db22', --insert players steam id
    }, --to add more just copy this table paste and change id
    {
        steamid = 'id2'
    }
}

Config.LockPicking = {
    minigameSettings = {
        MaxAttemptsPerLock = 3,
        lockpickitem = 'lockpick',
        difficulty = 50,
        hintdelay = 500,
    },
}