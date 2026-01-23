Config = {}

Config.defaultlang = 'en_lang' -- Set your language here
-----------------------------------------------------

-- Enable to see debug messages in the client and server consoles
Config.devMode = {
    active = false -- Default: false / DO NOT Enable on Live Server
}
-----------------------------------------------------

Config.Keys = {
    lock = 0x760A9C6F, -- [G] lock/unlock
    lockpick = 0xCEFD9220 -- [E]
}
-----------------------------------------------------

Config.CloseOnRestart = true -- Close all doors on server restart
-----------------------------------------------------

Config.ManageDoorLocks = 'ManageDoorLocks' -- Command to open door management menu
-----------------------------------------------------

Config.DoorRadius = 1.5 -- Default: 1.5 / Maximum Distance from Door to Operate
-----------------------------------------------------

-- These are groups that will be able to create, manage and operate doors (set in 'group' in 'characters' table)
Config.AllowedGroups = {
    { groupName = 'admin' }, -- Example: { groupName = 'admin'
}

-- These are jobs that will be able to create, manage and operate doors *Optional* (set in 'job' in 'characters' table)
Config.AllowedJobs = {
    { jobName = '' }, -- Example: { jobName = 'police' }
}
-----------------------------------------------------

Config.LockPicking = {
    minigameScript = 'bcc_minigames', -- bcc_minigames or rsd_lockpick
    allowlockpicking = true, -- If true players will be able to lockpick doors
    minigameSettings = {
        MaxAttemptsPerLock = 3, -- How many fail attempts are allowed before game over
        lockpickitem = 'lockpick', -- Item Name in Database
        -- Only bcc_minigames settings
        difficulty = 20, -- +- threshold to the stage degree (bigger number means easier)
        hintdelay = 100, -- Only bcc_minigames
        randomDegrees = true, -- If true, pins will be random degrees; if false, use static degrees
        staticDegrees = {     -- Static degrees to use when randomDegrees is false
            90,               -- Stage 1 degree (0-360)
            180,              -- Stage 2 degree (0-360)
            270,              -- Stage 3 degree (0-360)
        },
    },
}

-- Resolve custom maping doors conflicts
Config.SpooniEmerald = true -- If you are using spooni's emerald map and have door conflicts set this to true
Config.SpooniManzanitaPost = true -- If you are using spooni's manzanita post map and have door conflicts set this to true
Config.SpooniPronghornRanch = true -- If you are using spooni's pronghorn ranch map and have door conflicts set this to true

-- Seed jail doors behavior: when true, seed jail doors from `client/doorhashes.lua` on start.
-- If false, seeding will still run automatically on first-run when the `doorlocks` table is empty.
Config.SeedJailDoorsOnStart = false
