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
            jobs[#jobs+1] = value -- Add the job to the list
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
            ids[#ids+1] = tonumber(value) -- Add the ID to the list
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
        devPrint("Sending to server: jobs: " .. json.encode(jobs) .. ", keyItem: " .. tostring(keyItem) .. ", ids: " .. json.encode(ids))

        -- Send the door, jobs, keyItem, and ids data to the server
        TriggerServerEvent('bcc-doorlocks:InsertIntoDB', door, jobs, keyItem, ids)
        BCCDoorLocksMenu:Close() -- Close the menu after confirming
    end)

    -- Back button to close the menu
    mainDoorLocksMenu:RegisterElement('button', {
        label = "Close", -- Label for the back button
        slot = "footer",
        style = {}
    }, function()
        BCCDoorLocksMenu:Close() -- Close the current menu
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
        label = label, -- Label for the input
        placeholder = placeholder, -- Placeholder for the input field
        inputType = inputType, -- Input type: text, number, etc.
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
            callback(inputValue) -- Process the input value via the callback
            BCCDoorLocksMenu:Close() -- Close the current menu
            doorCreationMenu(door) -- Reopen the door creation menu
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
