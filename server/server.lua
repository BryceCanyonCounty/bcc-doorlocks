----- Pulling Essentials -----
local VORPcore = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()

-- Helper function for debugging in DevMode
if Config.DevMode then
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. message .. "^0")
    end
else
    function devPrint(message) end -- No-op if DevMode is disabled
end

RegisterServerEvent('bcc-doorlocks:InsertIntoDB', function(doorTable, jobs, keyItem, ids)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    devPrint("InsertIntoDB triggered with doorTable: " .. json.encode(doorTable))

    -- Ensure keyItem, jobs, and ids are properly set, with sensible defaults
    local kItem = (keyItem ~= nil and keyItem ~= "") and keyItem or 'none'
    local pIds = (#ids > 0 and ids ~= nil) and json.encode(ids) or '[]'
    local allowedJobs = (#jobs > 0 and jobs ~= nil) and json.encode(jobs) or '[]'
    -- Check if the door already exists in the database
    local doesDoorExist = MySQL.query.await('SELECT * FROM `doorlocks` WHERE `doorinfo` = ?', { json.encode(doorTable) })
    if not doesDoorExist then
        devPrint("Database query failed while checking if the door exists.")
        VORPcore.NotifyRightTip(_source, _U("dbError"), 4000)
        return
    end
    if #doesDoorExist <= 0 then
        -- Insert the door if it doesn't exist
        MySQL.query.await(
            'INSERT INTO `doorlocks` (`jobsallowedtoopen`, `keyitem`, `locked`, `doorinfo`, `ids_allowed`) VALUES (?, ?, ?, ?, ?)',
            { allowedJobs, kItem, 'true', json.encode(doorTable), pIds })
        devPrint("Door inserted into DB with jobs: " .. allowedJobs .. ", key: " .. kItem .. ", ids: " .. pIds)

        TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, true, true, false, false)

        VORPcore.NotifyRightTip(_source, _U("doorCreated"), 4000)
    else
        devPrint("Door already exists in DB")
        VORPcore.NotifyRightTip(_source, _U("doorExists"), 4000)
    end

    -- Fetch the door ID and send it back to the client
    local result2 = MySQL.query.await('SELECT * FROM `doorlocks` WHERE `doorinfo` = ?', { json.encode(doorTable) })
    if #result2 > 0 then
        devPrint("Creation ID caught for doorID: " .. result2[1].doorid)
        TriggerClientEvent('bcc-doorlocks:ExportCreationIdCatch', _source, result2[1].doorid)
    end
end)
RegisterServerEvent("bcc-doorlocks:AdminCheck", function()
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end

    local character = user.getUsedCharacter
    if not character then
        devPrint("Character object is nil for source: " .. tostring(_source))
        return 
    end

    devPrint("AdminCheck triggered for user: " .. (character.charIdentifier or "Unknown Identifier"))

    local admin = false

    -- Check if the user is an admin
    if character.group == Config.adminGroup then
        admin = true
        TriggerClientEvent('bcc-doorlocks:AdminVarCatch', _source, true)
    end

    -- Check if the user has allowed jobs
    if not admin then
        for _, v in pairs(Config.AllowedJobs) do
            if character.job == v.jobname then
                admin = true
                TriggerClientEvent('bcc-doorlocks:AdminVarCatch', _source, true)
                break
            end
        end
    end

    if not admin then
        devPrint("User is not an admin or in an allowed job.")
    end
end)

RegisterServerEvent('bcc-doorlocks:InitLoadDoorLocks', function()
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    devPrint("InitLoadDoorLocks triggered by source: " .. _source)

    local result = MySQL.query.await('SELECT * FROM `doorlocks`')

    for k, v in pairs(result) do
        local lockVal
        if v.locked == 'true' then
            lockVal = true
        else
            lockVal = false
        end

        local doorTable = json.decode(v.doorinfo)
        devPrint("Setting door status for doorTable: " .. json.encode(doorTable) .. " Locked: " .. tostring(lockVal))
        TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', _source, doorTable, lockVal, true, false, false)
    end
end)

RegisterNetEvent('bcc-doorlocks:AddPlayerToDoor', function(door, playerId)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    local character = user.getUsedCharacter
    local playerId = character.charIdentifier
    -- Validate inputs
    if not door or not playerId then
        print("^1[bcc-doorlocks] Error: Invalid door or playerId in AddPlayerToDoor event.^0")
        return
    end

    print("^2[bcc-doorlocks] Processing AddPlayerToDoor. Door: " ..
        json.encode(door) .. ", Player ID: " .. tostring(playerId) .. "^0")

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
            print("^2[bcc-doorlocks] Player added to existing door.^0")
        else
            print("^3[bcc-doorlocks] Player already has access to this door.^0")
        end
        doorId = result[1].doorid
    else
        -- Door does not exist, create it and fetch the ID
        local insertResult = MySQL.query.await("INSERT INTO doorlocks (doorinfo, ids_allowed, locked) VALUES (?, ?, ?)",
            { json.encode(door), json.encode({ playerId }), 'true' })
        if insertResult and insertResult.insertId then
            doorId = insertResult.insertId
        else
            print("^1[bcc-doorlocks] Error: Failed to insert door into database.^0")
            return
        end
        print("^2[bcc-doorlocks] New door created and player added.^0")
    end

    if doorId then
        print("^2[bcc-doorlocks] Returning door ID: " .. tostring(doorId) .. "^0")
        TriggerClientEvent('bcc-doorlocks:ExportCreationIdCatch', _source, doorId)
    else
        print("^1[bcc-doorlocks] Error: Failed to retrieve or create door ID.^0")
    end
end)


RegisterServerEvent('bcc-doorlocks:GetAllDoorlocks')
AddEventHandler('bcc-doorlocks:GetAllDoorlocks', function()
    local _source = source
    local result = MySQL.query.await('SELECT * FROM doorlocks')

    if result then
        TriggerClientEvent('bcc-doorlocks:ReceiveAllDoorlocks', _source, result)
    else
        TriggerClientEvent('VORPcore:NotifyRightTip', _source, "Failed to fetch doorlocks.", 4000)
    end
end)

BccUtils.RPC:Register("bcc-doorlocks:GetDoorField", function(params, cb, recSource)
    local doorId = params.doorId
    local field = params.field

    if not doorId or not field then
        devPrint("Invalid parameters for GetDoorField: Door ID or field is missing.")
        cb(nil)
        return
    end

    local door = DoorLocksAPI:GetDoorById(doorId)

    if not door then
        devPrint("Door ID not found in API: " .. tostring(doorId))
        cb(nil)
        return
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
        devPrint("Invalid field specified for GetDoorField: " .. tostring(field))
        cb(nil)
        return
    end

    devPrint("Fetched " .. field .. " for door ID: " .. tostring(doorId) .. ": " .. json.encode(result))
    cb(json.encode(result)) -- Return the field's value as JSON
end)

BccUtils.RPC:Register("bcc-doorlocks:UpdateDoorlock", function(params, cb, recSource)
    local doorId = params.doorId
    local field = params.field
    local value = params.value

    -- Validate parameters
    if not doorId or not field or not value then
        devPrint("^1Invalid parameters for UpdateDoorlock: Door ID, field, or value is missing.^0")
        cb(false)
        return
    end

    local door = DoorLocksAPI:GetDoorById(doorId)

    -- Validate door existence
    if not door then
        devPrint("^1Door ID not found in API: " .. tostring(doorId) .. "^0")
        cb(false)
        return
    end

    -- Update the specified field
    if field == 'jobsallowedtoopen' then
        local jobs = type(value) == "string" and json.decode(value) or value
        if not jobs or type(jobs) ~= "table" then
            devPrint("^1Invalid jobs data provided for door ID: " .. tostring(doorId) .. "^0")
            cb(false)
            return
        end
        door:UpdateAllowedJobs(jobs)
        devPrint("^2Updated allowed jobs for door ID: " .. tostring(doorId) .. "^0")
    elseif field == 'keyitem' then
        if type(value) ~= "string" then
            devPrint("^1Invalid key item provided for door ID: " .. tostring(doorId) .. "^0")
            cb(false)
            return
        end
        door:UpdateKeyItem(value)
        devPrint("^2Updated key item for door ID: " .. tostring(doorId) .. "^0")
    elseif field == 'ids_allowed' then
        local ids = type(value) == "string" and json.decode(value) or value
        if not ids or type(ids) ~= "table" then
            devPrint("^1Invalid allowed IDs provided for door ID: " .. tostring(doorId) .. "^0")
            cb(false)
            return
        end
        door:UpdateAllowedIds(ids)
        devPrint("^2Updated allowed IDs for door ID: " .. tostring(doorId) .. "^0")
    else
        devPrint("^1Invalid field specified for UpdateDoorlock: " .. tostring(field) .. "^0")
        cb(false)
        return
    end

    -- Return success after updates
    cb(true)
end)

RegisterServerEvent('bcc-doorlocks:GetDoorlockDetails')
AddEventHandler('bcc-doorlocks:GetDoorlockDetails', function(doorId)
    local _source = source
    local result = MySQL.query.await('SELECT * FROM doorlocks WHERE doorid = ?', { doorId })

    if result and #result > 0 then
        TriggerClientEvent('bcc-doorlocks:ReceiveDoorlockDetails', _source, result[1])
    else
        TriggerClientEvent('VORPcore:NotifyRightTip', _source, "Door not found.", 4000)
    end
end)

-- Register the RPC for deleting a door lock
BccUtils.RPC:Register("bcc-doorlocks:DeleteDoorlock", function(params, cb, recSource)
    local doorlockId = params.doorlockId

    -- Validate the doorlock ID
    if not doorlockId then
        devPrint("^1Invalid doorlock ID provided for deletion.^0")
        cb(false)
        return
    end

    -- Query the database to check if the door exists
    local result = MySQL.query.await('SELECT * FROM doorlocks WHERE doorid = ?', { doorlockId })

    if result and #result > 0 then
        -- Delete the door lock from the database
        MySQL.query.await('DELETE FROM doorlocks WHERE doorid = ?', { doorlockId })
        devPrint("^2Successfully deleted door lock ID: " .. tostring(doorlockId) .. "^0")
        cb(true)

        -- Optionally, notify other clients about the deletion if needed
        VORPcore.NotifyRightTip(_source, _U("doorDeleted"), 4000)
    else
        devPrint("^1Door lock ID not found: " .. tostring(doorlockId) .. "^0")
        cb(false)
    end
end)

RegisterServerEvent('bcc-doorlocks:DeleteDoor', function(doorTable)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    devPrint("DeleteDoor triggered for doorTable: " .. json.encode(doorTable))

    MySQL.query.await('DELETE FROM `doorlocks` WHERE `doorinfo` = ?', { json.encode(doorTable) })
    devPrint("Door deleted from DB for doorTable: " .. json.encode(doorTable))

    TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, false, false, true, false)

    VORPcore.NotifyRightTip(_source, _U("doorDeleted"), 4000)
end)

RegisterServerEvent('bcc-doorlocks:ServDoorStatusSet', function(doorTable, locked, lockpicked)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    local character = user.getUsedCharacter
    devPrint("ServDoorStatusSet triggered with door status: " .. tostring(locked))

    local lockedparam = locked and 'true' or 'false'
    local jobFound, keyFound = false, false

    -- Fetch door information from the database
    local result = MySQL.query.await('SELECT * FROM `doorlocks` WHERE `doorinfo` = ?', { json.encode(doorTable) })

    if not result or #result == 0 then
        devPrint("^1Error: Door not found in the database.^0")
        return
    end

    local doorData = result[1]

    -- Check jobsallowedtoopen
    local jobsAllowed = json.decode(doorData.jobsallowedtoopen or "[]")
    if jobsAllowed and type(jobsAllowed) == "table" then
        for _, job in pairs(jobsAllowed) do
            if job == "none" then
                devPrint("Job is set to 'none', skipping job check.")
                jobFound = true
                break
            elseif character.job == job then
                devPrint("Job match found for user: " .. character.identifier)
                jobFound = true
                break
            end
        end
    end

    -- If jobFound, update the lock status
    if jobFound then
        MySQL.query.await('UPDATE `doorlocks` SET `locked` = ? WHERE `doorinfo` = ?',
            { lockedparam, json.encode(doorTable) })
        TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, locked, true, false, true, _source)
        return
    end

    -- Check keyitem if no job match
    if doorData.keyitem ~= "none" then
        if exports.vorp_inventory:getItemCount(_source, nil, tostring(doorData.keyitem)) >= 1 then
            devPrint("Key item found for user: " .. character.identifier)
            keyFound = true
            MySQL.query.await('UPDATE `doorlocks` SET `locked` = ? WHERE `doorinfo` = ?',
                { lockedparam, json.encode(doorTable) })
            TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, locked, true, false, true, _source)
            return
        end
    end

    -- Check ids_allowed if no key match
    local idsAllowed = json.decode(doorData.ids_allowed or "[]")
    if idsAllowed and type(idsAllowed) == "table" then
        for _, id in pairs(idsAllowed) do
            if character.charIdentifier == id then
                devPrint("ID match found for user: " .. character.identifier)
                MySQL.query.await('UPDATE `doorlocks` SET `locked` = ? WHERE `doorinfo` = ?',
                    { lockedparam, json.encode(doorTable) })
                TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, locked, true, false, true, _source)
                return
            end
        end
    end

    -- Handle lockpicked case
    if lockpicked then
        devPrint("Lockpick successful for doorTable: " .. json.encode(doorTable))
        MySQL.query.await('UPDATE `doorlocks` SET `locked` = ? WHERE `doorinfo` = ?',
            { lockedparam, json.encode(doorTable) })
        TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, locked, true, false, true, _source)
        return
    end

    -- If all checks fail, deny access
    devPrint("^1Access denied for user: " .. character.identifier .. "^0")
end)

RegisterServerEvent('bcc-doorlocks:LockPickCheck', function(doorTable)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    devPrint("LockPickCheck triggered for user: " .. _source)
    local lockpickItem = Config.LockPicking.minigameSettings.lockpickitem
    local metadata = nil

    local itemCount = exports.vorp_inventory:getItemCount(_source, nil, lockpickItem, metadata)

    if itemCount >= 1 then
        devPrint("User has lockpick item")
        TriggerClientEvent('bcc-doorlocks:lockpickingMinigame', _source, doorTable)
    else
        devPrint("User does not have lockpick item")
        VORPcore.NotifyRightTip(_source, _U("noLockpick"), 4000)
    end
end)

RegisterServerEvent('bcc-doorlocks:RemoveLockpick', function()
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end
    devPrint("Removing lockpick for user: " .. _source)

    local lockpickItem = Config.LockPicking.minigameSettings.lockpickitem
    local metadata = nil

    exports.vorp_inventory:subItem(_source, lockpickItem, 1, metadata, function(success)
        if success then
            devPrint("Lockpick successfully removed from user: " .. _source)
        else
            devPrint("Failed to remove lockpick for user: " .. _source)
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
