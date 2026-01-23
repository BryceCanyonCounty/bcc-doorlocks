function GetDoor(type)
	DBG:Info("GetDoor function called with type: " .. tostring(type))
	local modelAimedAt, door = {}, nil

	-- Instructions based on type
	if type == 'creation' then
		DBG:Info("Creation mode selected.")
		Core.NotifyRightTip(_U("createDoorInstructions"), 4000)
	elseif type == 'deletion' then
		DBG:Info("Deletion mode selected.")
		Core.NotifyRightTip(_U("deleteDoorInstructions"), 4000)
	else
		DBG:Error("Invalid type provided to GetDoor function.")
		return nil
	end

	local type2 = false
	while true do
		Wait(0)
		local playerId = PlayerId()
		local ped = PlayerPedId()

		-- Check for `G` key release
		if not type2 then
			if IsControlJustReleased(0, 0x760A9C6F) then -- `G` key
				DBG:Info("Key `G` released.")
				type2 = true
			end

			-- Handle free aim detection
			if IsPlayerFreeAiming(playerId) then
				local hasEntity, entity = GetEntityPlayerIsFreeAimingAt(playerId)
				if hasEntity then
					local model = GetEntityModel(entity)
					if model ~= nil and model ~= 0 then
						DBG:Info("Entity model detected: " .. tostring(model))
						for k, v in pairs(Doorhashes) do
							if v[2] == model then
								table.insert(modelAimedAt, v)
							end
						end

						-- Match door hash with entity coordinates
						for _, v in ipairs(modelAimedAt) do
							local aimedEntityCoords = GetEntityCoords(entity)
							if GetDistanceBetweenCoords(v[4], v[5], v[6], aimedEntityCoords.x, aimedEntityCoords.y, aimedEntityCoords.z, true) < 1 then
								door = v
								break
							end
						end

						if door then
							DBG:Info("Door found.")
							BccUtils.Misc.DrawText3D(door[4], door[5], door[6] + 1, _U("questionLocking"))
							if IsControlJustReleased(0, 0x760A9C6F) then -- Confirm with `G` key
								DBG:Info("Confirmed door selection with `G` key.")
								break
							end
						end
					end
				end
			end
		else
			-- Handle proximity-based detection
			local playerCoords = GetEntityCoords(ped)
			for _, v in pairs(Doorhashes) do
				if GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, v[4], v[5], v[6], true) < 1.5 then
					door = v
					break
				end
			end

			if door then
				DBG:Info("Proximity-based door found.")
				BccUtils.Misc.DrawText3D(door[4], door[5], door[6] + 1, _U("questionLocking"))
				if IsControlJustReleased(0, 0x760A9C6F) then
					DBG:Info("Confirmed proximity-based door selection with `G` key.")
					break
				end
			end
		end
	end

	if door then
		DBG:Info("Returning door: " .. json.encode(door))
		return door
	else
		DBG:Error("No door found or selected.")
		return nil
	end
end

function SetDoorLockStatus(doorHash, locked, deletion) -- Function to lock and unlock doors
	DBG:Info("SetDoorLockStatus called with doorHash: " ..
		doorHash .. ", locked: " .. tostring(locked) .. ", deletion: " .. tostring(deletion))
	Citizen.InvokeNative(0xD99229FE93B46286, doorHash, 1, 1, 0, 0, 0, 0)
	local doorstatus = DoorSystemGetDoorState(doorHash)
	if deletion then
		DBG:Info("Deleting door with doorHash: " .. doorHash)
		Citizen.InvokeNative(0x6BAB9442830C7F53, doorHash, 2)
		Wait(1000)
		Citizen.InvokeNative(0x6BAB9442830C7F53, doorHash, 0)
	else
		if locked then
			if doorstatus ~= 1 then
				DBG:Info("Locking door.")
				Citizen.InvokeNative(0x6BAB9442830C7F53, doorHash, 1)
				DoorSystemSetOpenRatio(doorHash, 0.0, true)
			end
		else
			if doorstatus ~= 0 then
				DBG:Info("Unlocking door.")
				Citizen.InvokeNative(0x6BAB9442830C7F53, doorHash, 0)
			end
		end
	end
end

local DoorHashes = {}
function LockAndUnlockDoorHandler(doorTable) -- Function to lock/unlock doors
	DBG:Info("LockAndUnlockDoorHandler called with doorTable: " .. json.encode(doorTable))
	local LockGroup = BccUtils.Prompts:SetupPromptGroup()
	local UnlockGroup = BccUtils.Prompts:SetupPromptGroup()
	local LockPrompt = LockGroup:RegisterPrompt(_U("lockDoor"), Config.Keys.lock, 1, 1, true, 'hold', { timedeventhash = "MEDIUM_TIMED_EVENT" })
	local UnlockPrompt = UnlockGroup:RegisterPrompt(_U("unlockDoor"), Config.Keys.lock, 1, 1, true, 'hold', { timedeventhash = "MEDIUM_TIMED_EVENT" })
	local LockpickPrompt = nil
	if Config.LockPicking.allowlockpicking then
		LockpickPrompt = UnlockGroup:RegisterPrompt(_U("lockpickDoor"), Config.Keys.lockpick, 1, 1, true, 'hold', { timedeventhash = "MEDIUM_TIMED_EVENT" })
	end

	local doorHash = doorTable[1]
	if not DoorHashes[doorHash] then
		DoorHashes[doorHash] = true
	else
		return
	end

	local radius = tonumber(Config.DoorRadius)
	while true do
		Wait(0)
		local playerPos = GetEntityCoords(PlayerPedId())
		local doorPos = vector3(doorTable[4], doorTable[5], doorTable[6])
		local dist = #(playerPos - doorPos)
		local doorStatus = DoorSystemGetDoorState(doorTable[1])
		if doorStatus == 2 then break end
		if dist <= radius then
			if doorStatus ~= 1 then
				LockGroup:ShowGroup(_U("doorManage"))
				if LockPrompt:HasCompleted() then
                    DBG:Info("Locking door via prompt.")
                    TriggerServerEvent('bcc-doorlocks:ServDoorStatusSet', doorTable, true, false)
				end
			elseif doorStatus ~= 0 then
				UnlockGroup:ShowGroup(_U("doorManage"))
				if UnlockPrompt:HasCompleted() then
					DBG:Info("Unlocking door via prompt.")
					TriggerServerEvent('bcc-doorlocks:ServDoorStatusSet', doorTable, false, false)
				end
				if Config.LockPicking.allowlockpicking then
					if LockpickPrompt and LockpickPrompt:HasCompleted() then
						DBG:Info("Lockpicking door via prompt.")
						TriggerServerEvent('bcc-doorlocks:LockPickCheck', doorTable)
					end
				end
			end
		elseif dist >= 30 and dist < 100 then
			Wait(1500)
		elseif dist >= 100 then
			Wait(3000)
		end
	end
end

RegisterNetEvent('bcc-doorlocks:lockpickingMinigame', function(doorTable)
	DBG:Info("lockpickingMinigame event triggered for doorTable: " .. json.encode(doorTable))
	if Config.LockPicking.minigameScript == 'bcc_minigames' then
        -- Determine degrees based on config
        local degrees = {}
        if Config.LockPicking.minigameSettings.randomDegrees then

            -- Use random degrees
            degrees = {
                math.random(0, 360),
                math.random(0, 360),
                math.random(0, 360)
            }
        else
            -- Use static degrees from config
            degrees = Config.LockPicking.minigameSettings.staticDegrees or { 90, 180, 270 } -- Fallback if not configured
        end

		local cfg = {
			focus = true,
			cursor = true,
			maxattempts = Config.LockPicking.minigameSettings.MaxAttemptsPerLock or 3,
			threshold = Config.LockPicking.minigameSettings.difficulty or 20,
			hintdelay = Config.LockPicking.minigameSettings.hintdelay or 100,
			stages = {
                {
                    deg = degrees[1] -- 0-360 degrees
                },
                {
                    deg = degrees[2] -- 0-360 degrees
                },
                {
                    deg = degrees[3] -- 0-360 degrees
                }
            }
		}

		MiniGame.Start('lockpick', cfg, function(result)
            local success = (type(result) == 'table' and result.unlocked) or (result == true)
			if success then
				DBG:Info("Lockpick succeeded.")
				Core.NotifyRightTip(_U("lockPicked"), 4000)
				TriggerServerEvent('bcc-doorlocks:ServDoorStatusSet', doorTable, false, true)
                return
			else
				DBG:Info("Lockpick failed.")
				TriggerServerEvent('bcc-doorlocks:RemoveLockpick')
                return
			end
		end)
	elseif Config.LockPicking.minigameScript == 'rsd_lockpick' then
		local stand = 1 -- set 0 to stand, 1 to crouch
		local attempt = Config.LockPicking.minigameSettings.MaxAttemptsPerLock
		local result = exports.rsd_lockpick:StartLockPick(stand, attempt)
		if result then
			DBG:Info("RSD lockpick succeeded.")
			Core.NotifyRightTip(_U("lockPicked"), 4000)
			TriggerServerEvent('bcc-doorlocks:ServDoorStatusSet', doorTable, false, true)
		else
			DBG:Info("RSD lockpick failed.")
			TriggerServerEvent('bcc-doorlocks:RemoveLockpick')
		end
	end
end)

local function LoadAnim(animDict)
    DBG.Info(string.format('Loading animation dictionary: %s', tostring(animDict)))
    if HasAnimDictLoaded(animDict) then return end

    RequestAnimDict(animDict)
    local timeout = 10000
    local startTime = GetGameTimer()

    while not HasAnimDictLoaded(animDict) do
        if GetGameTimer() - startTime > timeout then
            print('Failed to load dictionary:', animDict)
            return
        end
        Wait(10)
    end
    DBG.Info(string.format('Animation dictionary loaded: %s', tostring(animDict)))
end

function PlayKeyAnim() -- Play key animation
	DBG:Info("Playing key animation.")
	local playerPed = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local prop = CreateObject(joaat('P_KEY02X'), playerCoords.x, playerCoords.y, playerCoords.z + 0.2, true, true, true)
	local boneIndex = GetEntityBoneIndexByName(playerPed, "SKEL_R_Finger12")
    local animDict = "script_common@jail_cell@unlock@key"
    local animName = "action"
    LoadAnim(animDict)
	TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, 2500, 31, 0, true, false, false)
	Wait(750)
	AttachEntityToEntity(prop, playerPed, boneIndex, 0.02, 0.0120, -0.00850, 0.024, -160.0, 200.0, true, true, false, true, 1, true, false, false)
	while true do
		Wait(50)
		if not IsEntityPlayingAnim(playerPed, animDict, animName, 3) then
			DeleteObject(prop)
			ClearPedTasksImmediately(playerPed)
			break
		end
	end
end
