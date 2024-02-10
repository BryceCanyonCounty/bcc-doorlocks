function doorCreationMenu(door)
    local jobs, keyItem, ids = {}, nil, {}
    local jobValue1, jobValue2, jobValue3, idValue  = '', '', '', ''
    local doorMenu = FeatherMenu:RegisterMenu('feather:character:menu', {
        top = '10%',
        left = '2%',
        ['720width'] = '500px',
        ['1080width'] = '600px',
        ['2kwidth'] = '700px',
        ['4kwidth'] = '900px',
        style = {
            -- ['height'] = '500px'
            -- ['border'] = '5px solid white',
            -- ['background-image'] = 'none',
            -- ['background-color'] = '#515A5A'
        },
        draggable = false,
        canclose = true
    }, {
        opened = function()
            inMenu = true
        end,
        closed = function()
            inMenu = false
        end,
    })
    local mainPage = doorMenu:RegisterPage('bcc-doorlocks:mainPage')
    mainPage:RegisterElement('header', {
        value = _U('menuTitle'),
        slot = "header",
        style = {}
    })
    mainPage:RegisterElement('subheader', {
        value = _U('menuSubTitle'),
        slot = "header",
        style = {}
    })
    mainPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })
    mainPage:RegisterElement('input', {
        label = _U("setJob"),
        placeholder = _U('jobPlace'),
        -- persist = false,
        style = {
            -- ['background-image'] = 'none',
            -- ['background-color'] = '#E8E8E8',
            -- ['color'] = 'black',
            -- ['border-radius'] = '6px'
        }
    }, function(data)
        jobValue1 = data.value
        -- This gets triggered whenever the input value changes
        table.insert(jobs, jobValue1)
    end)
    mainPage:RegisterElement('input', {
        label = _U("setJob"),
        placeholder = _U('jobPlace'),
        -- persist = false,
        style = {
            -- ['background-image'] = 'none',
            -- ['background-color'] = '#E8E8E8',
            -- ['color'] = 'black',
            -- ['border-radius'] = '6px'
        }
    }, function(data)
        jobValue2 = data.value
        -- This gets triggered whenever the input value changes
        table.insert(jobs, jobValue2)
    end)
    mainPage:RegisterElement('input', {
        label = _U("setJob"),
        placeholder = _U('jobPlace'),
        -- persist = false,
        style = {
            -- ['background-image'] = 'none',
            -- ['background-color'] = '#E8E8E8',
            -- ['color'] = 'black',
            -- ['border-radius'] = '6px'
        }
    }, function(data)
        jobValue3 = data.value
        -- This gets triggered whenever the input value changes
        table.insert(jobs, jobValue3)
    end)
    mainPage:RegisterElement('input', {
        label = _U("setKeyItem"),
        placeholder = _U('keyItem'),
        -- persist = false,
        style = {
            -- ['background-image'] = 'none',
            -- ['background-color'] = '#E8E8E8',
            -- ['color'] = 'black',
            -- ['border-radius'] = '6px'
        }
    }, function(data)
        keyItem = data.value
    end)
    mainPage:RegisterElement('input', {
        label = _U("setIds"),
        placeholder = _U("idsPlace"),
        -- persist = false,
        style = {
            -- ['background-image'] = 'none',
            -- ['background-color'] = '#E8E8E8',
            -- ['color'] = 'black',
            -- ['border-radius'] = '6px'
        }
    }, function(data)
        idValue = data.value
        -- This gets triggered whenever the input value changes
        table.insert(ids, tonumber(idValue))
    end)
    mainPage:RegisterElement('bottomline', {
        slot = "content",
        style = {}
    })
    mainPage:RegisterElement('button', {
        label = _U("confirm"),
        style = {},
        sound = {
            action = "SELECT",
            soundset = "RDRO_Character_Creator_Sounds"
        },
    }, function()
        TriggerServerEvent('bcc-doorlocks:InsertIntoDB', door, jobs, keyItem, ids)
        doorMenu:Close({
            sound = {
                action = "SELECT",
                soundset = "RDRO_Character_Creator_Sounds"
            }
        })
    end)
    if not inMenu then
        doorMenu:Open({
            -- cursorFocus = false,
            -- menuFocus = false,
            startupPage = mainPage,
            sound = {
                action = "SELECT",
                soundset = "RDRO_Character_Creator_Sounds"
            }
        })
    end
end