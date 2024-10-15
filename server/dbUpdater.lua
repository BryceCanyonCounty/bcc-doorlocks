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
