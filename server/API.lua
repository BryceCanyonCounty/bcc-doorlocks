DoorLocksAPI = {} -- Set up the API table

exports("getDoorLocksAPI", function()
    return DoorLocksAPI
end)

-- Get a door by its ID
function DoorLocksAPI:GetDoorById(doorId)
    local doorData = MySQL.query.await("SELECT * FROM doorlocks WHERE doorid = ?", { doorId })
    if #doorData > 0 then
        local door = {}
        door.id = doorData[1].doorid
        door.info = json.decode(doorData[1].doorinfo)
        door.jobs = json.decode(doorData[1].jobsallowedtoopen)
        door.keyItem = doorData[1].keyitem
        door.locked = doorData[1].locked == "true"
        door.idsAllowed = json.decode(doorData[1].ids_allowed)

        function door:GetDoorInfo()
            return self.info
        end

        function door:GetAllowedJobs()
            return self.jobs
        end

        function door:GetKeyItem()
            return self.keyItem
        end

        function door:IsLocked()
            return self.locked
        end

        function door:GetAllowedIds()
            return self.idsAllowed
        end

        function door:UpdateLockStatus(lockStatus)
            local lockValue = lockStatus and "true" or "false"
            MySQL.query.await("UPDATE doorlocks SET locked = ? WHERE doorid = ?", { lockValue, self.id })
            self.locked = lockStatus
        end

        function door:UpdateAllowedJobs(newJobs)
            local jobsJSON = json.encode(newJobs)
            MySQL.query.await("UPDATE doorlocks SET jobsallowedtoopen = ? WHERE doorid = ?", { jobsJSON, self.id })
            self.jobs = newJobs
        end

        function door:UpdateKeyItem(newKeyItem)
            MySQL.query.await("UPDATE doorlocks SET keyitem = ? WHERE doorid = ?", { newKeyItem, self.id })
            self.keyItem = newKeyItem
        end

        function door:UpdateAllowedIds(newIds)
            local idsJSON = json.encode(newIds)
            MySQL.query.await("UPDATE doorlocks SET ids_allowed = ? WHERE doorid = ?", { idsJSON, self.id })
            self.idsAllowed = newIds
        end

        function door:DeleteDoor()
            MySQL.query.await("DELETE FROM doorlocks WHERE doorid = ?", { self.id })
        end

        return door
    else
        return false
    end
end

-- Get all doors
function DoorLocksAPI:GetAllDoors()
    local doorsData = MySQL.query.await("SELECT * FROM doorlocks")
    if #doorsData > 0 then
        local doors = {}
        for _, door in ipairs(doorsData) do
            table.insert(doors, {
                id = door.doorid,
                info = json.decode(door.doorinfo),
                jobs = json.decode(door.jobsallowedtoopen),
                keyItem = door.keyitem,
                locked = door.locked == "true",
                idsAllowed = json.decode(door.ids_allowed)
            })
        end
        return doors
    else
        return false
    end
end

-- Add a new door
function DoorLocksAPI:AddDoor(doorInfo, allowedJobs, keyItem, allowedIds, lockStatus)
    local lockValue = lockStatus and "true" or "false"
    local jobsJSON = json.encode(allowedJobs)
    local idsJSON = json.encode(allowedIds)
    local doorInfoJSON = json.encode(doorInfo)

    MySQL.query.await(
        "INSERT INTO doorlocks (doorinfo, jobsallowedtoopen, keyitem, locked, ids_allowed) VALUES (?, ?, ?, ?, ?)",
        { doorInfoJSON, jobsJSON, keyItem or "none", lockValue, idsJSON }
    )
end
