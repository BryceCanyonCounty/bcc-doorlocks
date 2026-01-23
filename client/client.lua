IsAdmin = false

RegisterNetEvent('vorp:SelectedCharacter') -- This runs on client char select, setting all door statuses for the client
AddEventHandler('vorp:SelectedCharacter', function()
    DBG:Info("SelectedCharacter event triggered. Requesting door locks and admin check.")
    TriggerServerEvent('bcc-doorlocks:InitLoadDoorLocks')
    TriggerServerEvent('bcc-doorlocks:AdminCheck')
end)

RegisterNetEvent('bcc-doorlocks:AdminVarCatch', function(var) -- admin check catch
    DBG:Info("AdminVarCatch event triggered. Admin status: " .. tostring(var))
    if var then
        IsAdmin = true
    end
end)

RegisterCommand(Config.ManageDoorLocks, function() -- Command to create a door
    if IsAdmin then
        ManageDoorLocksMenu()
    else
        print("You don't have the required group or job to use this command.")
    end
end, false)

------ Locking, and unlocking area -----
RegisterNetEvent('bcc-doorlocks:ClientSetDoorStatus',
    function(doorTable, locked, triggerLockHandler, deletion, playerOpened, _source)
        if not doorTable then
            DBG:Error("doorTable is nil in ClientSetDoorStatus event.")
            return
        end

        if type(doorTable) ~= "table" or not doorTable[1] then
            DBG:Error("doorTable is invalid or missing key [1] in ClientSetDoorStatus event. Data: " .. tostring(doorTable))
            return
        end

        DBG:Info("ClientSetDoorStatus event triggered. Door status: " .. tostring(locked) .. ", Deletion: " .. tostring(deletion))

        -- Ensure the first element of doorTable is valid before proceeding
        SetDoorLockStatus(doorTable[1], locked, deletion)

        if playerOpened then
            local player = GetPlayerServerId(tonumber(PlayerId()))
            Wait(200)
            if player == _source then
                DBG:Info("Player opened door, playing key animation.")
                PlayKeyAnim()
            end
        end

        if triggerLockHandler then
            DBG:Info("Lock and unlock door handler triggered for doorTable: " .. json.encode(doorTable))
            LockAndUnlockDoorHandler(doorTable)
        end
    end)

----- Exports -------
ExportDoorCreationId = nil
ExportDoorCreationFinished = false

exports('createDoor', function()
    DBG:Info("Exported function 'createDoor' called. Starting door creation process.")
    local door = GetDoor('creation')
    if door then
        DoorCreationMenu(door) -- Call without extra parameters for initial empty state
        while not ExportDoorCreationFinished do
            Wait(100)
        end
        ExportDoorCreationFinished = false
        DBG:Info("Door creation finished. Door ID: " .. tostring(ExportDoorCreationId))
        return ExportDoorCreationId
    else
        DBG:Error("No door selected for creation.")
        return nil
    end
end)

exports('deleteDoor', function()
    DBG:Info("Exported function 'deleteDoor' called. Starting door deletion process.")
    local door = GetDoor('deletion')
    TriggerServerEvent('bcc-doorlocks:DeleteDoor', door)
end)

exports('deleteSpecificDoor', function(doorTable)
    DBG:Info("Exported function 'deleteSpecificDoor' called for doorTable: " .. json.encode(doorTable))
    for k, v in pairs(Doorhashes) do
        if v[1] == doorTable[1] then
            DBG:Info("Matching door found, deleting door.")
            TriggerServerEvent('bcc-doorlocks:DeleteDoor', v)
            break
        end
    end
end)

exports('addPlayerToDoor', function(playerId)
    DBG:Info("Starting door creation and player addition process.")
    local door = GetDoor('creation') -- Call GetDoor to handle the creation process

    if not door then
        DBG:Error("Door creation failed. No door selected or created.")
        return false
    end

    -- Ensure playerId is valid
    if not playerId then
        DBG:Error("Invalid playerId provided.")
        return false
    end

    -- Trigger the server event to add the player to the door
    TriggerServerEvent('bcc-doorlocks:AddPlayerToDoor', door, playerId)

    -- Wait for the door ID from the server
    local doorId = nil
    while not ExportDoorCreationFinished do
        Wait(100)
    end
    doorId = ExportDoorCreationId
    ExportDoorCreationFinished = false
    TriggerServerEvent('bcc-doorlocks:InitLoadDoorLocks')
    if doorId then
        DBG:Info("Door creation finished. Door ID: " .. tostring(doorId))
        return doorId
    else
        DBG:Error("Failed to create door or retrieve door ID.")
        return false
    end
end)

RegisterNetEvent('bcc-doorlocks:ExportCreationIdCatch', function(doorid)
    DBG:Info("ExportCreationIdCatch event triggered. Door ID: " .. tostring(doorid))
    ExportDoorCreationId = doorid
    ExportDoorCreationFinished = true
end)
