RegisterNetEvent('bcc-doorlocks:InsertIntoDB', function(doorTable, jobs, keyItem, ids)
    local src = source
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return
    end
    DBG:Info("InsertIntoDB triggered with doorTable: " .. json.encode(doorTable))

    -- Ensure keyItem, jobs, and ids are properly set, with sensible defaults
    local kItem = (keyItem ~= nil and keyItem ~= "") and keyItem or 'none'
    local pIds = (#ids > 0 and ids ~= nil) and json.encode(ids) or '[]'
    local allowedJobs = (#jobs > 0 and jobs ~= nil) and json.encode(jobs) or '[]'
    -- Check if the door already exists in the database
    local doesDoorExist = MySQL.query.await('SELECT * FROM `doorlocks` WHERE `doorinfo` = ?', { json.encode(doorTable) })
    if not doesDoorExist then
        DBG:Error("Database query failed while checking if the door exists.")
        Core.NotifyRightTip(src, _U("dbError"), 4000)
        return
    end
    if #doesDoorExist <= 0 then
        -- Insert the door if it doesn't exist
        MySQL.query.await(
            'INSERT INTO `doorlocks` (`jobsallowedtoopen`, `keyitem`, `locked`, `doorinfo`, `ids_allowed`) VALUES (?, ?, ?, ?, ?)',
            { allowedJobs, kItem, 'true', json.encode(doorTable), pIds })
        DBG:Success("Door inserted into DB with jobs: " .. allowedJobs .. ", key: " .. kItem .. ", ids: " .. pIds)

        TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, true, true, false, false)

        Core.NotifyRightTip(src, _U("doorCreated"), 4000)
    else
        DBG:Warning("Door already exists in DB")
        Core.NotifyRightTip(src, _U("doorExists"), 4000)
    end

    -- Fetch the door ID and send it back to the client
    local result2 = MySQL.query.await('SELECT * FROM `doorlocks` WHERE `doorinfo` = ?', { json.encode(doorTable) })
    if #result2 > 0 then
        DBG:Info("Creation ID caught for doorID: " .. result2[1].doorid)
        TriggerClientEvent('bcc-doorlocks:ExportCreationIdCatch', src, result2[1].doorid)
    end
end)

local function CheckAdmin(character)
    -- Check if the user has an allowed group
    for _, group in pairs(Config.AllowedGroups) do
        if character.group == group.groupName then
            return true
        end
    end

    -- Check if the user has an allowed job
    for _, job in pairs(Config.AllowedJobs) do
        if character.job == job.jobName then
            return true
        end
    end

    return false
end

RegisterNetEvent("bcc-doorlocks:AdminCheck", function()
    local src = source
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return
    end

    local character = user.getUsedCharacter
    if not character then
        DBG:Error("Character object is nil for source: " .. tostring(src))
        return
    end

    local charId = character.charIdentifier
    DBG:Info("AdminCheck triggered for character: " .. (charId or "Unknown Identifier"))

    if CheckAdmin(character) then
        TriggerClientEvent('bcc-doorlocks:AdminVarCatch', src, true)
        DBG:Info("Character " .. charId .. " is an admin for door management.")
        return
    end

    DBG:Warning("Character " .. charId .. " is not in an allowed group or job.")
end)

RegisterNetEvent('bcc-doorlocks:InitLoadDoorLocks', function()
    local src = source
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return
    end
    DBG:Info("InitLoadDoorLocks triggered by source: " .. src)

    local result = MySQL.query.await('SELECT * FROM `doorlocks`')

    for k, v in pairs(result) do
        local lockVal
        if v.locked == 'true' then
            lockVal = true
        else
            lockVal = false
        end

        local doorTable = json.decode(v.doorinfo)
        DBG:Info("Setting door status for doorTable: " .. json.encode(doorTable) .. " Locked: " .. tostring(lockVal))
        TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', src, doorTable, lockVal, true, false, false)
    end
end)

RegisterNetEvent('bcc-doorlocks:AddPlayerToDoor', function(door, playerId)
    local src = source
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return
    end
    local character = user.getUsedCharacter
    local playerId = character.charIdentifier
    -- Validate inputs
    if not door or not playerId then
        DBG:Error("Invalid door or playerId in AddPlayerToDoor event.")
        return
    end

    DBG:Info("Processing AddPlayerToDoor. Door: " .. json.encode(door) .. ", Player ID: " .. tostring(playerId))

    -- Check if the door already exists
    local result = MySQL.query.await("SELECT * FROM doorlocks WHERE doorinfo = ?", { json.encode(door) })
    local doorId

    if result and #result > 0 then
        -- Door exists, update allowed IDs
        local idsAllowed = json.decode(result[1].ids_allowed or "[]")
        if not table.contains(idsAllowed, playerId) then
            table.insert(idsAllowed, playerId)
            MySQL.query.await("UPDATE doorlocks SET ids_allowed = ? WHERE doorinfo = ?",
                { json.encode(idsAllowed), json.encode(door) })
            DBG:Success("Player added to existing door.")
        else
            DBG:Warning("Player already has access to this door.")
        end
        doorId = result[1].doorid
    else
        -- Door does not exist, create it and fetch the ID
        local insertResult = MySQL.query.await("INSERT INTO doorlocks (doorinfo, ids_allowed, locked) VALUES (?, ?, ?)",
            { json.encode(door), json.encode({ playerId }), 'true' })
        if insertResult and insertResult.insertId then
            doorId = insertResult.insertId
        else
            DBG:Error("Failed to insert door into database.")
            return
        end
        DBG:Success("New door created and player added.")
    end

    if doorId then
        DBG:Info("Returning door ID: " .. tostring(doorId))
        TriggerClientEvent('bcc-doorlocks:ExportCreationIdCatch', src, doorId)
    else
        DBG:Error("Failed to retrieve or create door ID.")
    end
end)


RegisterNetEvent('bcc-doorlocks:GetAllDoorlocks', function()
    local src = source
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return
    end
    local result = MySQL.query.await('SELECT * FROM doorlocks')

    if result then
        TriggerClientEvent('bcc-doorlocks:ReceiveAllDoorlocks', src, result)
    else
        TriggerClientEvent('Core:NotifyRightTip', src, "Failed to fetch doorlocks.", 4000)
    end
end)

BccUtils.RPC:Register("bcc-doorlocks:GetDoorField", function(params, cb, recSource)
    local src = recSource
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return cb(nil)
    end
    local doorId = params.doorId
    local field = params.field

    if not doorId or not field then
        DBG:Error("Invalid parameters for GetDoorField: Door ID or field is missing.")
        return cb(nil)
    end

    local door = DoorLocksAPI:GetDoorById(doorId)

    if not door then
        DBG:Error("Door ID not found in API: " .. tostring(doorId))
        return cb(nil)
    end

    -- Dynamically fetch the specified field
    local result
    if field == 'jobsallowedtoopen' then
        result = door:GetAllowedJobs()
    elseif field == 'ids_allowed' then
        result = door:GetAllowedIds()
    elseif field == 'keyitem' then
        result = door:GetKeyItem()
    else
        DBG:Error("Invalid field specified for GetDoorField: " .. tostring(field))
        return cb(nil)
    end

    DBG:Info("Fetched " .. field .. " for door ID: " .. tostring(doorId) .. ": " .. json.encode(result))
    cb(json.encode(result)) -- Return the field's value as JSON
end)

BccUtils.RPC:Register("bcc-doorlocks:UpdateDoorlock", function(params, cb, recSource)
    local src = recSource
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return cb(false)
    end
    local doorId = params.doorId
    local field = params.field
    local value = params.value

    -- Validate parameters
    if not doorId or not field or not value then
        DBG:Error("Invalid parameters for UpdateDoorlock: Door ID, field, or value is missing.")
        return cb(false)
    end

    local door = DoorLocksAPI:GetDoorById(doorId)

    -- Validate door existence
    if not door then
        DBG:Error("Door ID not found in API: " .. tostring(doorId))
        return cb(false)
    end

    -- Update the specified field
    if field == 'jobsallowedtoopen' then
        local jobs = type(value) == "string" and json.decode(value) or value
        if not jobs or type(jobs) ~= "table" then
            DBG:Error("Invalid jobs data provided for door ID: " .. tostring(doorId))
            return cb(false)
        end
        door:UpdateAllowedJobs(jobs)
        DBG:Success("Updated allowed jobs for door ID: " .. tostring(doorId))
    elseif field == 'keyitem' then
        if type(value) ~= "string" then
            DBG:Error("Invalid key item provided for door ID: " .. tostring(doorId))
            return cb(false)
        end
        door:UpdateKeyItem(value)
        DBG:Success("Updated key item for door ID: " .. tostring(doorId))
    elseif field == 'ids_allowed' then
        local ids = type(value) == "string" and json.decode(value) or value
        if not ids or type(ids) ~= "table" then
            DBG:Error("Invalid allowed IDs provided for door ID: " .. tostring(doorId))
            return cb(false)
        end
        door:UpdateAllowedIds(ids)
        DBG:Success("Updated allowed IDs for door ID: " .. tostring(doorId))
    else
        DBG:Error("Invalid field specified for UpdateDoorlock: " .. tostring(field))
        return cb(false)
    end

    -- Return success after updates
    cb(true)
end)

RegisterNetEvent('bcc-doorlocks:GetDoorlockDetails', function(doorId)
    local src = source
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return
    end
    local result = MySQL.query.await('SELECT * FROM doorlocks WHERE doorid = ?', { doorId })

    if result and #result > 0 then
        TriggerClientEvent('bcc-doorlocks:ReceiveDoorlockDetails', src, result[1])
    else
        TriggerClientEvent('Core:NotifyRightTip', src, "Door not found.", 4000)
    end
end)

-- Register the RPC for deleting a door lock
BccUtils.RPC:Register("bcc-doorlocks:DeleteDoorlock", function(params, cb, recSource)
    local src = recSource
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return cb(false)
    end
    local doorlockId = params.doorlockId

    -- Validate the doorlock ID
    if not doorlockId then
        DBG:Error("Invalid doorlock ID provided for deletion.")
        return cb(false)
    end

    -- Query the database to check if the door exists
    local result = MySQL.query.await('SELECT * FROM doorlocks WHERE doorid = ?', { doorlockId })

    if result and #result > 0 then
        -- Delete the door lock from the database
        MySQL.query.await('DELETE FROM doorlocks WHERE doorid = ?', { doorlockId })
        DBG:Success("Successfully deleted door lock ID: " .. tostring(doorlockId))
        Core.NotifyRightTip(src, _U("doorDeleted"), 4000)
        return cb(true)
    else
        DBG:Error("Door lock ID not found: " .. tostring(doorlockId))
        return cb(false)
    end
end)

RegisterNetEvent('bcc-doorlocks:DeleteDoor', function(doorTable)
    local src = source
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return
    end
    DBG:Info("DeleteDoor triggered for doorTable: " .. json.encode(doorTable))
    MySQL.query.await('DELETE FROM `doorlocks` WHERE `doorinfo` = ?', { json.encode(doorTable) })
    DBG:Success("Door deleted from DB for doorTable: " .. json.encode(doorTable))

    TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, false, false, true, false)

    Core.NotifyRightTip(src, _U("doorDeleted"), 4000)
end)

RegisterNetEvent('bcc-doorlocks:ServDoorStatusSet', function(doorTable, locked, lockpicked)
    local src = source
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return
    end

    local character = user.getUsedCharacter
    local charId = character.charIdentifier
    DBG:Info("ServDoorStatusSet triggered with door status: " .. tostring(locked))

    local lockedparam = locked and 'true' or 'false'
    local isAllowed = false
    local result, doorData

    -- Handle lockpicked case
    if lockpicked then
        DBG:Info("Lockpick successful for doorTable: " .. json.encode(doorTable))
        isAllowed = true
    end

    -- Check if the user has admin privileges from config (group/job)
    if not isAllowed then
        if CheckAdmin(character) then
            isAllowed = true
        end
    end

    if not isAllowed then
        -- Fetch door information from the database
        result = MySQL.query.await('SELECT * FROM `doorlocks` WHERE `doorinfo` = ?', { json.encode(doorTable) })

        if not result or #result == 0 then
            DBG:Error("Door not found in database.")
            return
        end

        doorData = result[1]
    end

    if not isAllowed then
        -- Check jobsallowedtoopen database field
        local jobsAllowed = json.decode(doorData.jobsallowedtoopen or "[]")
        if jobsAllowed and type(jobsAllowed) == "table" then
            for _, job in pairs(jobsAllowed) do
                if job == "none" then
                    DBG:Info("Job is set to 'none', skipping job check.")
                    break
                elseif character.job == job then
                    DBG:Info("Job match found for character: " .. charId)
                    isAllowed = true
                    break
                end
            end
        end
    end

    if not isAllowed then
        -- Check inventory for keyitem
        if doorData.keyitem ~= "none" then
            if exports.vorp_inventory:getItemCount(src, nil, tostring(doorData.keyitem)) >= 1 then
                DBG:Info("Key item found for character: " .. charId)
                isAllowed = true
            end
        end
    end

    if not isAllowed then
        -- Check ids_allowed database field
        local idsAllowed = json.decode(doorData.ids_allowed or "[]")
        if idsAllowed and type(idsAllowed) == "table" then
            for _, id in pairs(idsAllowed) do
                if charId == id then
                    DBG:Info("ID match found for character: " .. charId)
                    MySQL.query.await('UPDATE `doorlocks` SET `locked` = ? WHERE `doorinfo` = ?', { lockedparam, json.encode(doorTable) })
                    TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, locked, true, false, true, src)
                    return
                end
            end
        end
    end

    -- If isAllowed, update the lock status
    if isAllowed then
        MySQL.query.await('UPDATE `doorlocks` SET `locked` = ? WHERE `doorinfo` = ?', { lockedparam, json.encode(doorTable) })
        TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, locked, true, false, true, src)
        return
    end

    -- If all checks fail, deny access
    DBG:Error("Access denied for character: " .. charId .. " to doorTable: " .. json.encode(doorTable))
end)

RegisterNetEvent('bcc-doorlocks:LockPickCheck', function(doorTable)
    local src = source
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return
    end
    DBG:Info("LockPickCheck triggered for user: " .. src)

    local lockpickItem = Config.LockPicking.minigameSettings.lockpickitem
    local metadata = nil

    local itemCount = exports.vorp_inventory:getItemCount(src, nil, lockpickItem, metadata)

    if itemCount >= 1 then
        DBG:Info("User has lockpick item")
        TriggerClientEvent('bcc-doorlocks:lockpickingMinigame', src, doorTable)
    else
        DBG:Info("User does not have lockpick item")
        Core.NotifyRightTip(src, _U("noLockpick"), 4000)
    end
end)

RegisterNetEvent('bcc-doorlocks:RemoveLockpick', function()
    local src = source
    local user = Core.getUser(src)
    if not user then
        DBG:Error("User not found for source: " .. tostring(src))
        return
    end
    DBG:Info("Removing lockpick for user: " .. src)
    local lockpickItem = Config.LockPicking.minigameSettings.lockpickitem
    local metadata = nil

    exports.vorp_inventory:subItem(src, lockpickItem, 1, metadata, function(success)
        if success then
            DBG:Info("Lockpick successfully removed from user: " .. src)
        else
            DBG:Error("Failed to remove lockpick for user: " .. src)
        end
    end)
end)

function table.contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-doorlocks')
