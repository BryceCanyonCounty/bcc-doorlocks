local admin = false

RegisterNetEvent('vorp:SelectedCharacter') --This runs on client char select setting all doors statuses for the client
AddEventHandler('vorp:SelectedCharacter', function()
    TriggerServerEvent('bcc-doorlocks:InitLoadDoorLocks')
    TriggerServerEvent('bcc-doorlocks:AdminCheck')
end)

RegisterNetEvent('bcc-doorlocks:AdminVarCatch', function(adminAllowed)
    admin = adminAllowed
end)

RegisterCommand('createDoor', function() --command to create a door
    if admin then
        local door = getDoor('creation')
        doorCreationMenu(door)
    end
end)

RegisterCommand("deleteDoor", function() --command to delete a door
    if admin then
        local door = getDoor('deletion')
        TriggerServerEvent('bcc-doorlocks:DeleteDoor', door)
    end
end)

------ Locking, and unlocking area -----
RegisterNetEvent('bcc-doorlocks:ClientSetDoorStatus', function(doorTable, locked, triggerLockHandler, deletion, playerOpened) --This will set doors locked when triggered
    setDoorLockStatus(doorTable[1], locked, deletion)
    if playerOpened then
        playKeyAnim()
    end
    if triggerLockHandler then
        lockAndUnlockDoorHandler(doorTable)
    end
end)

CreateThread(function()
    if Config.DevMode then
        RegisterCommand('devboy', function()
            TriggerServerEvent('bcc-doorlocks:InitLoadDoorLocks')
            TriggerServerEvent('bcc-doorlocks:AdminCheck')
        end)
    end
end)

----- Exports -------
exports('createDoor', function()
    local door = getDoor('creation')
    doorCreationMenu(door)
    return door
end)

exports('deleteDoor', function()
    local door = getDoor('deletion')
    TriggerServerEvent('bcc-doorlocks:DeleteDoor', door)
end)

exports('deleteSpecificDoor', function(doorTable)
    for k,v in pairs(Doorhashes) do
        if v[1] == doorTable[1] then
            TriggerServerEvent('bcc-doorlocks:DeleteDoor', v) break
        end
    end
end)