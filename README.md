
# bcc-doorlocks

> This is an optimized, simple, and effective door lock script! It allows server admins to create doors that can be locked and unlocked by players!

## Features
- Each door can have up to 3 jobs that can unlock it!
- Each door can have its own key item to open!
- Each door can be lockpicked with a lockpick item!
- Can set an unlimited amount of character IDs allowed to lock and unlock doors!
- Exports for other scripts to create and delete doors!
- Command `/ManageDoorLocks` for admins to manage doors!
- Menu for creating and managing doors!

## How it works!
- To manage doors, use the `/ManageDoorLocks` command.
- **Create a door**: Aim with a gun at the door you want to lock, press "G," and use the menu to configure the door.
- **Delete a door**: Select the door from the list in the menu and remove it.
- Once a door is created, walk up to it, and you will see prompts on the bottom right of your screen for interaction.

## Dependencies
- [vorp_core](https://github.com/VORPCORE/vorp-core-lua)
- [vorp_inventory](https://github.com/VORPCORE/vorp_inventory-lua)
- [vorp_character](https://github.com/VORPCORE/vorp_character-lua)
- [feather-menu](https://github.com/FeatherFramework/feather-menu)
- [bcc-utils](https://github.com/BryceCanyonCounty/bcc-utils)
- [bcc-minigames](https://github.com/BryceCanyonCounty/bcc-minigames)

## Installation
1. Ensure the dependencies are installed and updated.
2. Add the `bcc-doorlocks` folder to your `resources` directory.
3. Add `ensure bcc-doorlocks` to your `server.cfg`.
4. The database schema will automatically initialize.
5. Restart your server.

## Updates from Recent Changes
- **Dynamic API Integration**:
  - Added an API (`DoorLocksAPI`) for retrieving, updating, and managing door data, such as:
    - `GetDoorById`
    - `AddDoor`
    - `UpdateAllowedJobs`
    - `UpdateKeyItem`
    - `UpdateAllowedIds`
- **Editing and Managing Doors**:
  - Added client-side menus to dynamically edit:
    - Allowed jobs.
    - Key items.
    - Allowed character IDs.
  - These menus utilize input fields and RPC calls for real-time updates.
- **Enhanced RPCs**:
  - New RPC handlers for:
    - `GetDoorField` to fetch specific door fields.
    - `UpdateDoorlock` for updating specific properties (e.g., `jobsallowedtoopen`, `keyitem`, `ids_allowed`).
- **Improved User Feedback**:
  - Notifications for successful or failed actions, ensuring clarity for users and admins.

## API
### Create Door
```lua
RegisterCommand('createDoorTest', function()
    local door = exports['bcc-doorlocks']:createDoor() 
    -- Creates a lock on the door and returns the door's table from `doorhashes.lua` for future deletion or storage.
end)
```
## Delete Door
```lua
RegisterCommand('deleteDoorTest', function()
    exports['bcc-doorlocks']:deleteDoor() 
    -- Deletes a door that you aim at and confirm.
end)
```

## Delete Specific Door
```lua
RegisterCommand('deleteSpecificDoorTest', function()
    local doorTable = { ... } -- Provide the specific door table
    exports['bcc-doorlocks']:deleteSpecificDoor(doorTable)
    -- Deletes a specific door using its table.
end)
```

## Add Player to Door
```lua
RegisterCommand('addPlayerToDoorTest', function()
    local playerId = 1 -- Replace with the actual player ID
    local doorId = exports['bcc-doorlocks']:addPlayerToDoor(playerId)
    -- Adds a player to the specified door and returns the updated door ID.
end)
```

## Update Door Fields
You can dynamically update door fields like `jobsallowedtoopen`, `keyitem`, and `ids_allowed` using RPC.

### Example: Update Allowed Jobs
```lua
BccUtils.RPC:Call("bcc-doorlocks:UpdateDoorlock", {
    doorId = 1, -- Replace with the door ID
    field = "jobsallowedtoopen",
    value = json.encode({"police", "doctor"})
}, function(success)
    if success then
        print("Jobs updated successfully.")
    else
        print("Failed to update jobs.")
    end
end)
```

### Example: Get Door Field
```lua
BccUtils.RPC:Call("bcc-doorlocks:GetDoorField", {
    doorId = 1, -- Replace with the door ID
    field = "jobsallowedtoopen"
}, function(result)
    if result then
        print("Current jobs: " .. result)
    else
        print("Failed to fetch jobs.")
    end
end)
```

## Notes
- Ensure all door data is properly stored and fetched using the provided API functions.
- Follow the installation and dependency requirements carefully to avoid compatibility issues.
