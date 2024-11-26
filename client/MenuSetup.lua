local jobs, keyItem, ids = {}, nil, {}

function doorCreationMenu(door)
    local mainDoorLocksMenu = BCCDoorLocksMenu:RegisterPage("bcc:doorlocks")

    -- Header for the door locks menu
    mainDoorLocksMenu:RegisterElement('header', {
        value = _U("menuTitle"), -- Title of the menu
        slot = 'header',
        style = {}
    })

    -- Divider line
    mainDoorLocksMenu:RegisterElement('line', {
        style = {}
    })

    -- Set Job button
    mainDoorLocksMenu:RegisterElement('button', {
        label = _U("setJob"), -- Button label for setting Job 1
        style = {}
    }, function()
        -- Capture the job input
        registerInput(_U("insertJob"), _U("setJob"), 'text', door, function(value)
            devPrint("Job added: " .. value)
            jobs[#jobs + 1] = value -- Add the job to the list
        end)
    end)

    -- Set Key Item button
    mainDoorLocksMenu:RegisterElement('button', {
        label = _U("setKeyItem"), -- Button label for setting key items
        style = {}
    }, function()
        -- Capture the key item input
        registerInput(_U("insertKeyItem"), _U("setKeyItem"), 'text', door, function(value)
            devPrint("Key item set: " .. value)
            keyItem = value -- Set the key item
        end)
    end)

    -- Set IDs button
    mainDoorLocksMenu:RegisterElement('button', {
        label = _U("setIds"), -- Button label for setting IDs
        style = {}
    }, function()
        -- Capture the IDs input
        registerInput(_U("insertId"), _U("setIds"), 'number', door, function(value)
            devPrint("ID added: " .. tostring(value))
            ids[#ids + 1] = tonumber(value) -- Add the ID to the list
        end)
    end)

    -- Divider line at the footer
    mainDoorLocksMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    -- Confirm button
    mainDoorLocksMenu:RegisterElement('button', {
        label = _U("Confirm"), -- Button label for confirming settings
        style = {},
        slot = "footer"
    }, function()
        -- Debug print to ensure that data is correct
        devPrint("Sending to server: jobs: " ..
            json.encode(jobs) .. ", keyItem: " .. tostring(keyItem) .. ", ids: " .. json.encode(ids))

        -- Send the door, jobs, keyItem, and ids data to the server
        TriggerServerEvent('bcc-doorlocks:InsertIntoDB', door, jobs, keyItem, ids)
        BCCDoorLocksMenu:Close() -- Close the menu after confirming
    end)

    -- Back button to close the menu
    mainDoorLocksMenu:RegisterElement('button', {
        label = _U('closeButton'),
        slot = "footer",
        style = {}
    }, function()
        BCCDoorLocksMenu:Close()
    end)

    -- Open the created menu
    BCCDoorLocksMenu:Open({
        startupPage = mainDoorLocksMenu
    })
end

-- Function to handle inputs for jobs, keyItem, and ids
function registerInput(label, placeholder, inputType, door, callback)
    local doorLockinputMenu = BCCDoorLocksMenu:RegisterPage('input_page')

    -- Header for the door locks menu
    doorLockinputMenu:RegisterElement('header', {
        value = _U("menuTitle"), -- Title of the menu
        slot = 'header',
        style = {}
    })

    -- Divider line
    doorLockinputMenu:RegisterElement('line', {
        style = {}
    })

    -- Input element
    local inputValue = nil -- Store the input value for confirmation

    -- Capture the input value
    doorLockinputMenu:RegisterElement('input', {
        label = label,             -- Label for the input
        placeholder = placeholder, -- Placeholder for the input field
        inputType = inputType,     -- Input type: text, number, etc.
        slot = 'content',
        style = {}
    }, function(data)
        if data.value and ((inputType == 'number' and tonumber(data.value)) or inputType == 'text') then
            inputValue = data.value -- Store the input value
            devPrint("Input received: " .. inputValue)
        else
            VORPcore.NotifyRightTip(_U("InvalidInput"), 4000) -- Notify user of invalid input
            devPrint("Invalid input received")
        end
    end)

    -- Divider line for footer
    doorLockinputMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    -- Confirm button to process input and go back to door creation
    doorLockinputMenu:RegisterElement('button', {
        label = _U('Confirm'), -- Confirm button label
        slot = "footer",
        style = {}
    }, function()
        devPrint("Confirm button clicked")
        if inputValue then
            devPrint("Input value to pass: " .. inputValue)
            callback(inputValue)                              -- Process the input value via the callback
            BCCDoorLocksMenu:Close()                          -- Close the current menu
            doorCreationMenu(door)                            -- Reopen the door creation menu
        else
            VORPcore.NotifyRightTip(_U("InvalidInput"), 4000) -- Notify user of invalid input
            devPrint("No valid input to process")
        end
    end)

    -- Back button to go back without confirming
    doorLockinputMenu:RegisterElement('button', {
        label = _U('BackButton'), -- Back button label
        slot = "footer",
        style = {}
    }, function()
        devPrint("Back button clicked, closing menu")
        BCCDoorLocksMenu:Close() -- Close the current menu
        doorCreationMenu(door)   -- Reopen the door creation menu
    end)

    -- Final bottom line element
    doorLockinputMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    -- Open the menu
    BCCDoorLocksMenu:Open({
        startupPage = doorLockinputMenu
    })
end

function manageDoorLocksMenu()
    local manageDoorLocksMenu = BCCDoorLocksMenu:RegisterPage("bcc:managedoorlocks")

    -- Header
    manageDoorLocksMenu:RegisterElement('header', {
        value = _U("manageDoorlocksTitle"), -- You'll need to add this to your locale file
        slot = 'header',
        style = {}
    })

    -- Divider line
    manageDoorLocksMenu:RegisterElement('line', {
        style = {}
    })

    -- View All Doorlocks button
    manageDoorLocksMenu:RegisterElement('button', {
        label = _U('createDoor'),
        style = {}
    }, function()
        BCCDoorLocksMenu:Close()
        local door = getDoor('creation')
        doorCreationMenu(door)
    end)

    -- View All Doorlocks button
    manageDoorLocksMenu:RegisterElement('button', {
        label = _U("viewDoorlocks"),
        style = {}
    }, function()
        -- Trigger event to fetch and display all doorlocks
        TriggerServerEvent('bcc-doorlocks:GetAllDoorlocks')
    end)

    -- Delete Doorlock button
    manageDoorLocksMenu:RegisterElement('button', {
        label = _U("deleteDoorlock"),
        style = {}
    }, function()
        BCCDoorLocksMenu:Close()
        local door = getDoor('deletion')
        TriggerServerEvent('bcc-doorlocks:DeleteDoor', door)
    end)

    -- Divider line at the footer
    manageDoorLocksMenu:RegisterElement('line', {
        style = {},
        slot = "footer"
    })

    -- Close button
    manageDoorLocksMenu:RegisterElement('button', {
        label = _U('closeButton'),
        slot = "footer",
        style = {}
    }, function()
        BCCDoorLocksMenu:Close()
    end)

    -- Divider line at the footer
    manageDoorLocksMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })

    -- Open the menu
    BCCDoorLocksMenu:Open({
        startupPage = manageDoorLocksMenu
    })
end

RegisterNetEvent('bcc-doorlocks:ReceiveAllDoorlocks')
AddEventHandler('bcc-doorlocks:ReceiveAllDoorlocks', function(doorlocks)
    local doorMenu = BCCDoorLocksMenu:RegisterPage("doorlocks_list")
    doorMenu:RegisterElement('header', {
        value = _U('allDoors'),
        slot = 'header',
        style = {}
    })

    doorMenu:RegisterElement('line', {
        style = {}
    })

    -- Iterate through all doorlocks
    for i, door in pairs(doorlocks) do
        doorMenu:RegisterElement('button', {
            label = _U('doorOptions') .. door.doorid,
            style = {}
        }, function()
            -- Handle specific door selection (edit or delete)
            manageSpecificDoorMenu(door)
        end)
    end

    doorMenu:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    -- Back to Manage Menu
    doorMenu:RegisterElement('button', {
        label = _U('BackButton'),
        slot = "footer",
        style = {}
    }, function()
        BCCDoorLocksMenu:Close()
        manageDoorLocksMenu()
    end)

    doorMenu:RegisterElement('bottomline', {
        slot = "footer",
        style = {}
    })

    BCCDoorLocksMenu:Open({
        startupPage = doorMenu
    })
end)

function manageSpecificDoorMenu(door)
    local specificDoorMenu = BCCDoorLocksMenu:RegisterPage("manage_specific_door")

    -- Header
    specificDoorMenu:RegisterElement('header', {
        value = _U('manageDoorid') .. door.doorid,
        slot = 'header',
        style = {}
    })

    -- Divider line
    specificDoorMenu:RegisterElement('line', {
        style = {}
    })

    -- Edit Door button
    specificDoorMenu:RegisterElement('button', {
        label = _U('editDoorid'),
        style = {}
    }, function()
        devPrint("Editing door ID: " .. door.doorid)
        editDoorMenu(door) -- Open the edit menu for the specific door
    end)

    -- Delete Door button
    specificDoorMenu:RegisterElement('button', {
        label = _U('removeDoor'),
        style = {}
    }, function()
        devPrint("Deleting door ID: " .. door.doorid)
        showConfirmationDialog(door.doorid) -- Open the confirmation dialog for deletion
    end)

    -- Divider line
    specificDoorMenu:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    -- Back Button
    specificDoorMenu:RegisterElement('button', {
        label = _U('BackButton'),
        slot = "footer",
        style = {}
    }, function()
        BCCDoorLocksMenu:Close()
        manageDoorLocksMenu() -- Return to the main door locks menu
    end)

    -- Open the menu
    BCCDoorLocksMenu:Open({
        startupPage = specificDoorMenu
    })
end

-- Add this helper function for delete confirmation
function showConfirmationDialog(doorlockId)
    local confirmMenu = BCCDoorLocksMenu:RegisterPage("confirm_delete")

    -- Header
    confirmMenu:RegisterElement('header', {
        value = _U("confirmDeleteTitle"), -- Localization key for the confirmation dialog title
        slot = 'header',
        style = {}
    })

    -- Divider line
    confirmMenu:RegisterElement('line', {
        style = {}
    })

    -- Confirm delete button
    confirmMenu:RegisterElement('button', {
        label = _U("confirmDelete"), -- Localization key for the confirm delete button
        style = {}
    }, function()
        BccUtils.RPC:Call("bcc-doorlocks:DeleteDoorlock", { doorlockId = doorlockId }, function(success)
            if success then
                VORPcore.NotifyRightTip(_U("doorRemoved"), 4000)      -- Notify that the door was removed
            else
                VORPcore.NotifyRightTip(_U("doorRemoveFailed"), 4000) -- Notify of failure
            end
        end)
        BCCDoorLocksMenu:Close()
    end)


    -- Cancel button
    confirmMenu:RegisterElement('button', {
        label = _U("cancel"), -- Localization key for the cancel button
        style = {}
    }, function()
        BCCDoorLocksMenu:Close()
        manageDoorLocksMenu() -- Return to main manage menu
    end)

    -- Open the confirmation dialog menu
    BCCDoorLocksMenu:Open({
        startupPage = confirmMenu
    })
end

function editDoorMenu(door)
    local editMenu = BCCDoorLocksMenu:RegisterPage("edit_doorlock")

    -- Header
    editMenu:RegisterElement('header', {
        value = _U('editingDoorId') .. door.doorid,
        style = {}
    })

    -- Divider line
    editMenu:RegisterElement('line', {
        style = {}
    })

    -- Edit Allowed Jobs
    editMenu:RegisterElement('button', {
        label = _U('editAllowedJobs'),
        style = {}
    }, function()
        local editAllowedJobMenu = BCCDoorLocksMenu:RegisterPage("edit_allowed_job_doorlock")

        -- Header
        editAllowedJobMenu:RegisterElement('header', {
            value = _U('updateAllowedJobs') .. door.doorid,
            style = {}
        })

        -- Divider line
        editAllowedJobMenu:RegisterElement('line', {
            style = {}
        })

        -- Input field for job
        local jobValue = nil -- Variable to store input value
        editAllowedJobMenu:RegisterElement('input', {
            label = _U('insertAlowedJob'),
            placeholder = _U('typeJobName'),
            style = {}
        }, function(data)
            jobValue = data.value
            devPrint("Captured job input: " .. tostring(jobValue))
        end)

        -- Submit Button
        editAllowedJobMenu:RegisterElement('button', {
            label = _U('submit'),
            slot = "footer",
            style = {}
        }, function()
            if not jobValue or jobValue == "" then
                VORPcore.NotifyRightTip(_U('jobNameCannotbeEmpty'), 4000)
                return
            end

            BccUtils.RPC:Call("bcc-doorlocks:GetDoorField", { doorId = door.doorid, field = 'jobsallowedtoopen' },
                function(existingJobs)
                    if not existingJobs then
                        existingJobs = "[]"
                    end

                    local jobsTable = json.decode(existingJobs) or {}

                    if not table.contains(jobsTable, jobValue) then
                        table.insert(jobsTable, jobValue)
                    else
                        VORPcore.NotifyRightTip(_U('jobAlreadyExists'), 4000)
                        return
                    end

                    BccUtils.RPC:Call("bcc-doorlocks:UpdateDoorlock", {
                        doorId = door.doorid,
                        field = 'jobsallowedtoopen',
                        value = json.encode(jobsTable)
                    }, function(success)
                        if success then
                            VORPcore.NotifyRightTip(_U('allowedJobUpdated'), 4000)
                        else
                            VORPcore.NotifyRightTip(_U('allowedJobFailed'), 4000)
                        end

                        -- Return to specific door management menu
                        devPrint("Returning to specific door management menu for door ID: " .. door.doorid)
                        manageSpecificDoorMenu(door)
                    end)
                end)
        end)

        -- Back Button
        editAllowedJobMenu:RegisterElement('button', {
            label = _U('BackButton'),
            slot = "footer",
            style = {}
        }, function()
            devPrint("Returning to specific door management menu for door ID: " .. door.doorid)
            manageSpecificDoorMenu(door)
        end)

        BCCDoorLocksMenu:Open({
            startupPage = editAllowedJobMenu
        })
    end)

    -- Edit Key Item
    editMenu:RegisterElement('button', {
        label = _U('editKeyItem'),
        style = {}
    }, function()
        local editKeyItemMenu = BCCDoorLocksMenu:RegisterPage("edit_keyitem_doorlock")

        -- Header
        editKeyItemMenu:RegisterElement('header', {
            value = _U('updateKeyItem') .. door.doorid,
            style = {}
        })

        -- Divider line
        editKeyItemMenu:RegisterElement('line', {
            style = {}
        })

        local keyItemValue = nil
        editKeyItemMenu:RegisterElement('input', {
            label = _U('insertKeyItem'),
            placeholder = _U('typeKeyItem'),
            style = {}
        }, function(data)
            keyItemValue = data.value

            if not keyItemValue or keyItemValue == "" then
                VORPcore.NotifyRightTip("Please provide a valid key item name.", 4000)
                return
            end

            devPrint("Captured key item input for door ID: " .. door.doorid .. " with value: " .. keyItemValue)
        end)

        editKeyItemMenu:RegisterElement('button', {
            label = _U('submit'),
            slot = "footer",
            style = {}
        }, function()
            if not keyItemValue or keyItemValue == "" then
                VORPcore.NotifyRightTip(_U('keyItemNameCannotBeEmpty'), 4000)
                return
            end

            BccUtils.RPC:Call("bcc-doorlocks:UpdateDoorlock",
                { doorId = door.doorid, field = 'keyitem', value = keyItemValue }, function(success)
                    if success then
                        VORPcore.NotifyRightTip(_U('keyItemUpdated'), 4000)
                    else
                        VORPcore.NotifyRightTip(_U('keyItemFailed'), 4000)
                    end
                    devPrint("Returning to specific door management menu for door ID: " .. door.doorid)
                    manageSpecificDoorMenu(door)
                end
            )
        end)

        editKeyItemMenu:RegisterElement('button', {
            label = _U('BackButton'),
            slot = "footer",
            style = {}
        }, function()
            manageSpecificDoorMenu(door)
        end)

        BCCDoorLocksMenu:Open({
            startupPage = editKeyItemMenu
        })
    end)

    -- Edit Allowed IDs
    editMenu:RegisterElement('button', {
        label = _U('editAllowedIDs'),
        style = {}
    }, function()
        local editAllowedIdMenu = BCCDoorLocksMenu:RegisterPage("edit_allowedid_doorlock")

        -- Header
        editAllowedIdMenu:RegisterElement('header', {
            value = _U('updateAllowedIDs') .. door.doorid,
            style = {}
        })

        -- Divider line
        editAllowedIdMenu:RegisterElement('line', {
            style = {}
        })

        local allowedIdValue = nil
        editAllowedIdMenu:RegisterElement('input', {
            label = _U('insertAllowedID'),
            placeholder = _U('typeCharacterID'),
            style = {}
        }, function(data)
            allowedIdValue = tonumber(data.value)

            if not allowedIdValue then
                VORPcore.NotifyRightTip("Please provide a valid numeric character ID.", 4000)
                return
            end

            devPrint("Captured allowed ID input for door ID: " ..
                door.doorid .. " with value: " .. tostring(allowedIdValue))
        end)

        editAllowedIdMenu:RegisterElement('button', {
            label = _U('submit'),
            slot = "footer",
            style = {}
        }, function()
            if not allowedIdValue then
                VORPcore.NotifyRightTip(_U('allowedIDCannotBeEmpty'), 4000)
                return
            end

            BccUtils.RPC:Call("bcc-doorlocks:GetDoorField", { doorId = door.doorid, field = 'ids_allowed' },
                function(existingIds)
                    if not existingIds then
                        existingIds = "[]"
                    end

                    local idsTable = json.decode(existingIds) or {}

                    if not table.contains(idsTable, allowedIdValue) then
                        table.insert(idsTable, allowedIdValue)
                    else
                        VORPcore.NotifyRightTip(_U('allowedIDExists'), 4000)
                        return
                    end

                    BccUtils.RPC:Call("bcc-doorlocks:UpdateDoorlock",
                        { doorId = door.doorid, field = 'ids_allowed', value = json.encode(idsTable) }, function(success)
                            if success then
                                VORPcore.NotifyRightTip(_U('allowedIDsUpdated'), 4000)
                            else
                                VORPcore.NotifyRightTip(_U('allowedIDsFailed'), 4000)
                            end
                            devPrint("Returning to specific door management menu for door ID: " .. door.doorid)
                            manageSpecificDoorMenu(door)
                        end
                    )
                end)
        end)

        editAllowedIdMenu:RegisterElement('button', {
            label = _U('BackButton'),
            slot = "footer",
            style = {}
        }, function()
            devPrint("Returning to specific door management menu for door ID: " .. door.doorid)
            manageSpecificDoorMenu(door)
        end)

        BCCDoorLocksMenu:Open({
            startupPage = editAllowedIdMenu
        })
    end)

    editMenu:RegisterElement('button', {
        label = _U('BackButton'),
        style = {}
    }, function()
        devPrint("Returning to specific door management menu for door ID: " .. door.doorid)
        manageSpecificDoorMenu(door)
    end)

    BCCDoorLocksMenu:Open({
        startupPage = editMenu
    })
end

function table.contains(tbl, element)
    for _, value in pairs(tbl) do
        if value == element then
            return true
        end
    end
    return false
end
