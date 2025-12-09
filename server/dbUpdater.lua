CreateThread(function()
    -- Create the doorlocks table if it doesn't exist
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `doorlocks` (
            `doorid` int NOT NULL AUTO_INCREMENT,
            `doorinfo` LONGTEXT NOT NULL,
            `jobsallowedtoopen` LONGTEXT NOT NULL DEFAULT 'none',
            `keyitem` varchar(50) NOT NULL DEFAULT 'none',
            `locked` varchar(50) NOT NULL DEFAULT 'false',
            PRIMARY KEY (`doorid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    -- Ensure the 'ids_allowed' column is added if it doesn't exist
    MySQL.query.await([[
        ALTER TABLE `doorlocks` 
        ADD COLUMN IF NOT EXISTS `ids_allowed` LONGTEXT DEFAULT NULL;
    ]])

    -- Print a success message to the console
    print("Database table for \x1b[35m\x1b[1m*doorlocks*\x1b[0m created or updated \x1b[32msuccessfully\x1b[0m.")
    -- Determine whether to seed: run when table empty OR when Config.SeedJailDoorsOnStart == true
    local shouldSeed = false
    local countOk, countRes = pcall(function()
        return MySQL.query.await('SELECT COUNT(*) as cnt FROM `doorlocks`')
    end)

    if Config.SeedJailDoorsOnStart then
        shouldSeed = true
    elseif countOk and countRes and countRes[1] and tonumber(countRes[1].cnt) == 0 then
        shouldSeed = true
    end

    if shouldSeed then
        local seededCount = 0
        local path = 'client/doorhashes.lua'

        local function insertDoorIfMissing(doorTable)
            local doorJson = json.encode(doorTable)
            local exists = nil
            local okq, qerr = pcall(function()
                exists = MySQL.query.await('SELECT * FROM `doorlocks` WHERE `doorinfo` = ?', { doorJson })
            end)
            if okq and exists and #exists == 0 then
                MySQL.query.await(
                    'INSERT INTO `doorlocks` (`doorinfo`, `jobsallowedtoopen`, `keyitem`, `locked`, `ids_allowed`) VALUES (?, ?, ?, ?, ?)',
                    { doorJson, 'none', 'none', 'true', json.encode({}) }
                )
                seededCount = seededCount + 1
            end
        end

        if type(LoadResourceFile) == 'function' then
            local resourceName = GetCurrentResourceName and GetCurrentResourceName() or 'bcc-doorlocks'
            local content = LoadResourceFile(resourceName, path)
            if content and content ~= '' then
                for block in content:gmatch('{([^}]-)}') do
                    local a, b, c, x, y, z = block:match('%s*(%-?%d+)%s*,%s*(%-?%d+)%s*,%s*"([^"]+)"%s*,%s*([%-%.%deE]+)%s*,%s*([%-%.%deE]+)%s*,%s*([%-%.%deE]+)')
                    if a and c and string.find(string.lower(c), 'jail', 1, true) then
                        local doorTable = { tonumber(a), tonumber(b), c, tonumber(x), tonumber(y), tonumber(z) }
                        insertDoorIfMissing(doorTable)
                    end
                end
                if seededCount > 0 then
                    print('[bcc-doorlocks] Seeded ' .. seededCount .. ' jail door(s) into doorlocks table.')
                else
                    print('[bcc-doorlocks] No new jail doors found to seed.')
                end
            else
                print('[bcc-doorlocks] Warning: LoadResourceFile returned empty content for ' .. path)
            end
        else
            print('[bcc-doorlocks] Warning: LoadResourceFile not available; skipping jail-door seeding.')
        end
    else
        print('[bcc-doorlocks] Skipping jail-door seeding (table not empty and SeedJailDoorsOnStart is false).')
    end

    if Config.CloseOnRestart then
        print("-------------------------------------------------------------")
        print("BCC-Doorlocks - Close on Restart \x1b[32mactive\x1b[0m.")
        print("All open Doors will \x1b[35m\x1b[1mclosed\x1b[0m")
        print("-------------------------------------------------------------")
        MySQL.query.await([[
            UPDATE doorlocks SET locked = 'true'
        ]])
    end
end)

