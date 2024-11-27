Config = {}

Config.defaultlang = 'en_lang' -- Set your language here current supported languages: "en_lang" = english

Config.DevMode = false -- false on live server

Config.CloseOnRestart = true -- Close all doors on server restart

Config.ManageDoorLocks = 'ManageDoorLocks'

Config.doorlocksDevCommand = 'doorlocksDev'

Config.DoorRadius = 1.5 -- Maximum Distance from Door to Operate

---------- Admin Configuration (Any group listed here will be able to create and delete doors!) ----------
Config.adminGroup = 'admin'

-- These are jobs that will be able to create doors just like the admins
Config.AllowedJobs = {
    {
        jobname = '' --the job name
    },
}

Config.LockPicking = {
    minigameScript = 'bcc_minigames', -- bcc_minigames or rsd_lockpick
    allowlockpicking = true, -- If true players will be able to lockpick doors
    minigameSettings = {
        MaxAttemptsPerLock = 3,
        lockpickitem = 'lockpick',
        difficulty = 50, -- Only bcc_minigames
        hintdelay = 500, -- Only bcc_minigames
    },
}
