----- Pulling Essentials -----
local VORPcore = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()

-- Helper function for debugging in DevMode
if Config.devMode then
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. message)
    end
else
    function devPrint(message) end -- No-op if DevMode is disabled
end

------ DataBase Handling ------
RegisterServerEvent('bcc-doorlocks:InsertIntoDB', function(doorTable, jobs, keyItem, ids)
    devPrint("InsertIntoDB triggered with doorTable: " .. json.encode(doorTable))
    local kItem, pIds
    if keyItem ~= nil then
        kItem = keyItem
    else
        kItem = 'none'
    end
    if ids ~= nil then
        pIds = ids
    else
        pIds = 'none'
    end
    local param = {
        ['jobs'] = json.encode(jobs),
        ['key'] = kItem,
        ['locked'] = 'true',
        ['doorinfo'] = json.encode(doorTable),
        ['ids'] = json.encode(pIds)
    }
    local _source = source

    local doesDoorExist = MySQL.query.await("SELECT * FROM doorlocks WHERE doorinfo=@doorinfo", param)
    if #doesDoorExist <= 0 then
        MySQL.query.await(
            "INSERT INTO doorlocks ( `jobsallowedtoopen`,`keyitem`,`locked`,`doorinfo`,`ids_allowed` ) VALUES ( @jobs,@key,@locked,@doorinfo,@ids )",
            param)
        devPrint("Door inserted into DB with doorTable: " .. json.encode(doorTable))
        TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, true, true, false, false)
        VORPcore.NotifyRightTip(_source, _U("doorCreated"), 4000)
    else
        devPrint("Door already exists in DB")
        VORPcore.NotifyRightTip(_source, _U("doorExists"), 4000)
    end

    local result2 = MySQL.query.await("SELECT * FROM doorlocks WHERE doorinfo=@doorinfo", param)
    if #result2 > 0 then
        devPrint("Creation ID caught for doorID: " .. result2[1].doorid)
        TriggerClientEvent('bcc-doorlocks:ExportCreationIdCatch', _source, result2[1].doorid)
    end
end)

RegisterServerEvent("bcc-doorlocks:AdminCheck", function()
    local _source, admin = source, false
    local character = VORPcore.getUser(_source).getUsedCharacter
    devPrint("AdminCheck triggered for user: " .. character.identifier)

    if character.group == Config.adminGroup then
        TriggerClientEvent('bcc-doorlocks:AdminVarCatch', _source, true)
    end

    if not admin then
        for k, v in pairs(Config.AllowedJobs) do
            if character.job == v.jobname then
                TriggerClientEvent('bcc-doorlocks:AdminVarCatch', _source, true)
                break
            end
        end
    end
end)

RegisterServerEvent('bcc-doorlocks:InitLoadDoorLocks', function()
    local _source = source
    devPrint("InitLoadDoorLocks triggered by source: " .. _source)

    local result = MySQL.query.await("SELECT * FROM doorlocks")
    for k, v in pairs(result) do
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

RegisterServerEvent('bcc-doorlocks:DeleteDoor', function(doorTable)
    devPrint("DeleteDoor triggered for doorTable: " .. json.encode(doorTable))
    local param = { ['doorinfo'] = json.encode(doorTable) }
    local _source = source
    exports.oxmysql:execute("DELETE FROM doorlocks WHERE doorinfo=@doorinfo", param)
    devPrint("Door deleted from DB for doorTable: " .. json.encode(doorTable))
    TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, false, false, true, false)
    VORPcore.NotifyRightTip(_source, _U("doorDeleted"), 4000)
end)

RegisterServerEvent('bcc-doorlocks:ServDoorStatusSet', function(doorTable, locked, lockpicked)
    devPrint("ServDoorStatusSet triggered with door status: " .. tostring(locked))
    local lockedparam = nil
    if locked then
        lockedparam = 'true'
    else
        lockedparam = 'false'
    end
    local param = { ['doorinfo'] = json.encode(doorTable), ['locked'] = lockedparam }
    local _source = source
    local jobFound, keyFound = false, false
    local character = VORPcore.getUser(_source).getUsedCharacter
    local result = MySQL.query.await("SELECT * FROM doorlocks WHERE doorinfo=@doorinfo", param)

    for k, v in pairs(json.decode(result[1].jobsallowedtoopen)) do
        if character.job == v then
            devPrint("Job found for user: " .. character.identifier)
            jobFound = true
            exports.oxmysql:execute("UPDATE doorlocks SET locked=@locked WHERE doorinfo=@doorinfo", param)
            TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, locked, true, false, true, _source)
        end
    end

    if not jobFound then
        if result[1].keyitem ~= "none" then
            if exports.vorp_inventory:getItemCount(_source, nil, tostring(result[1].keyitem)) >= 1 then
                devPrint("Key item found for user: " .. character.identifier)
                keyFound = true
                exports.oxmysql:execute("UPDATE doorlocks SET locked=@locked WHERE doorinfo=@doorinfo", param)
                TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, locked, true, false, true, _source)
            end
        end
    end

    if not keyFound then
        for k, v in pairs(json.decode(result[1].ids_allowed)) do
            if character.charIdentifier == v then
                devPrint("ID match found for user: " .. character.identifier)
                TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, locked, true, false, true, _source)
                break
            end
        end
    end

    if lockpicked then
        devPrint("Lockpick successful for doorTable: " .. json.encode(doorTable))
        TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, locked, true, false, true, _source)
    end
end)

RegisterServerEvent('bcc-doorlocks:LockPickCheck', function(doorTable)
    local _source = source
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

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-doorlocks')
