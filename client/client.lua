local admin = false

-- Helper function for debugging in DevMode
if Config.DevMode then
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. message)
    end
else
    function devPrint(message) end -- No-op if DevMode is disabled
end

RegisterNetEvent('vorp:SelectedCharacter') -- This runs on client char select, setting all door statuses for the client
AddEventHandler('vorp:SelectedCharacter', function()
    devPrint("SelectedCharacter event triggered. Requesting door locks and admin check.")
    TriggerServerEvent('bcc-doorlocks:InitLoadDoorLocks')
    TriggerServerEvent('bcc-doorlocks:AdminCheck')
end)

RegisterNetEvent('bcc-doorlocks:AdminVarCatch', function(var) -- admin check catch
    devPrint("AdminVarCatch event triggered. Admin status: " .. tostring(var))
    if var then
        admin = true
    end
end)

RegisterCommand(Config.CreateDoorCommand, function() -- Command to create a door
    if admin then
        devPrint("CreateDoorCommand executed by admin. Starting door creation process.")
        local door = getDoor('creation')
        doorCreationMenu(door)
    else
        devPrint("CreateDoorCommand attempted but player is not admin.")
    end
end, false)

RegisterCommand(Config.DeleteDoorCommand, function() -- Command to delete a door
    if admin then
        devPrint("DeleteDoorCommand executed by admin. Starting door deletion process.")
        local door = getDoor('deletion')
        TriggerServerEvent('bcc-doorlocks:DeleteDoor', door)
    else
        devPrint("DeleteDoorCommand attempted but player is not admin.")
    end
end, false)

------ Locking, and unlocking area -----
RegisterNetEvent('bcc-doorlocks:ClientSetDoorStatus', function(doorTable, locked, triggerLockHandler, deletion, playerOpened, _source)
    devPrint("ClientSetDoorStatus event triggered. Door status: " .. tostring(locked) .. ", Deletion: " .. tostring(deletion))
    setDoorLockStatus(doorTable[1], locked, deletion)
    
    if playerOpened then
        local player = GetPlayerServerId(tonumber(PlayerId()))
        Wait(200)
        if player == _source then
            devPrint("Player opened door, playing key animation.")
            playKeyAnim()
        end
    end

    if triggerLockHandler then
        devPrint("Lock and unlock door handler triggered for doorTable: " .. json.encode(doorTable))
        lockAndUnlockDoorHandler(doorTable)
    end
end)

CreateThread(function()
    if Config.DevMode then
        devPrint("DevMode is enabled, registering " ..Config.doorlocksDevCommand .." command.")
        RegisterCommand(Config.doorlocksDevCommand, function()
            devPrint(Config.doorlocksDevCommand .." command executed. Initializing door locks and admin check.")
            TriggerServerEvent('bcc-doorlocks:InitLoadDoorLocks')
            TriggerServerEvent('bcc-doorlocks:AdminCheck')
        end, false)
    end
end)

----- Exports -------
ExportDoorCreationId, ExportDoorCreationFinished = nil, false

exports('createDoor', function()
    devPrint("Exported function 'createDoor' called. Starting door creation process.")
    local door = getDoor('creation')
    doorCreationMenu(door)
    while not ExportDoorCreationFinished do
        Wait(100)
    end
    ExportDoorCreationFinished = false
    devPrint("Door creation finished. Door ID: " .. tostring(ExportDoorCreationId))
    return ExportDoorCreationId
end)

exports('deleteDoor', function()
    devPrint("Exported function 'deleteDoor' called. Starting door deletion process.")
    local door = getDoor('deletion')
    TriggerServerEvent('bcc-doorlocks:DeleteDoor', door)
end)

exports('deleteSpecificDoor', function(doorTable)
    devPrint("Exported function 'deleteSpecificDoor' called for doorTable: " .. json.encode(doorTable))
    for k, v in pairs(Doorhashes) do
        if v[1] == doorTable[1] then
            devPrint("Matching door found, deleting door.")
            TriggerServerEvent('bcc-doorlocks:DeleteDoor', v)
            break
        end
    end
end)

RegisterNetEvent('bcc-doorlocks:ExportCreationIdCatch', function(doorid)
    devPrint("ExportCreationIdCatch event triggered. Door ID: " .. tostring(doorid))
    ExportDoorCreationId = doorid
    ExportDoorCreationFinished = true
end)
