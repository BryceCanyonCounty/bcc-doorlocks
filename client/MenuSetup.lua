function doorCreationMenu(door)
    local mainDoorLocksMenu = BCCDoorLocksMenu:RegisterPage("bcc:doorlocks")
    local jobs, keyItem, ids = {}, nil, {}

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
        registerInput(_U("insertJob"), _U("setJob"), 'text', door, function(value)
            table.insert(jobs, value) -- Add the job to the list
        end)
    end)

    -- Set Key Item button
    mainDoorLocksMenu:RegisterElement('button', {
        label = _U("setKeyItem"), -- Button label for setting key items
        style = {}
    }, function()
        registerInput(_U("insertKeyItem"), _U("setKeyItem"), 'text', door, function(value)
            keyItem = value -- Set the key item
        end)
    end)

    -- Set IDs button
    mainDoorLocksMenu:RegisterElement('button', {
        label = _U("setIds"), -- Button label for setting IDs
        style = {}
    }, function()
        registerInput(_U("insertId"), _U("setIds"), 'number', door, function(value)
            table.insert(ids, tonumber(value)) -- Add the ID to the list
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
        -- Trigger event to save the door with the specified parameters
        TriggerServerEvent('bcc-doorlocks:InsertIntoDB', door, jobs, keyItem, ids)
        BCCDoorLocksMenu:Close() -- Close the menu after confirming
    end)

    -- Back button to go back to the previous menu or close
    mainDoorLocksMenu:RegisterElement('button', {
        label = "Close", -- Label for the back button
        slot = "footer",
        style = {}
    }, function()
        BCCDoorLocksMenu:Close() -- Close the current menu
    end)

    -- Final bottom line element
    mainDoorLocksMenu:RegisterElement('bottomline', {
        style = {},
        slot = "footer"
    })
    TextDisplay = mainDoorLocksMenu:RegisterElement('textdisplay', {
        value = _U('setJob_desc'),
        style = {},
        slot = "footer"
    })
    TextDisplay = mainDoorLocksMenu:RegisterElement('textdisplay', {
        value = _U('setKeyItem_desc'),
        style = {},
        slot = "footer"
    })
    TextDisplay = mainDoorLocksMenu:RegisterElement('textdisplay', {
        value = _U('setIds_desc'),
        style = {},
        slot = "footer"
    })
    
    -- Open the created menu
    BCCDoorLocksMenu:Open({
        startupPage = mainDoorLocksMenu
    })
end

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

    doorLockinputMenu:RegisterElement('input', {
        label = label, -- Label for the input
        placeholder = placeholder, -- Placeholder for the input field
        inputType = inputType, -- Input type: text, number, etc.
        slot = 'content',
        style = {}
    }, function(data)
        if data.value and ((inputType == 'number' and tonumber(data.value)) or inputType == 'text') then
            inputValue = data.value -- Store the input value
        else
            VORPcore.NotifyRightTip(_U("InvalidInput"), 4000) -- Notify user of invalid input
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
        if inputValue then
            callback(inputValue) -- Process the input value via the callback
            BCCDoorLocksMenu:Close() -- Close the current menu
            doorCreationMenu(door) -- Reopen the door creation menu
        else
            VORPcore.NotifyRightTip(_U("InvalidInput"), 4000) -- Notify user of invalid input
        end
    end)

    -- Back button to go back without confirming
    doorLockinputMenu:RegisterElement('button', {
        label = _U('BackButton'), -- Back button label
        slot = "footer",
        style = {}
    }, function()
        BCCDoorLocksMenu:Close() -- Close the current menu
        doorCreationMenu(door) -- Reopen the door creation menu
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
