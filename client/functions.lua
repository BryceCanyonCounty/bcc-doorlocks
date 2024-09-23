local VORPcore = exports.vorp_core:GetCore()
local FeatherMenu =  exports['feather-menu'].initiate()
BccUtils = exports['bcc-utils'].initiate()
MiniGame = exports['bcc-minigames'].initiate()

-- Helper function for debugging in DevMode
if Config.DevMode then
	function devPrint(message)
		print("^1[DEV MODE] ^4" .. message)
	end
else
	function devPrint(message) end -- No-op if DevMode is disabled
end

BCCDoorLocksMenu = FeatherMenu:RegisterMenu("bcc:doorlocks:mainmenu",
    {
        top = "5%",
        left = "5%",
        ["720width"] = "500px",
        ["1080width"] = "600px",
        ["2kwidth"] = "700px",
        ["4kwidth"] = "900px",
        style = {},
        contentslot = {
            style = {
                ["height"] = "450px",
                ["min-height"] = "250px"
            }
        },
        draggable = true
    },
    {
        opened = function()
            DisplayRadar(false)
        end,
        closed = function()
            DisplayRadar(true)
        end
    }
)

function getDoor(type) -- Function to unlock door
	devPrint("getDoor function called with type: " .. type)
	local modelAimedAt, door = {}, nil
	if type == 'creation' then
		devPrint("Creation mode selected")
		VORPcore.NotifyRightTip(_U("createDoorInstructions"), 4000)
	elseif type == 'deletion' then
		devPrint("Deletion mode selected")
		VORPcore.NotifyRightTip(_U("deleteDoorInstructions"), 4000)
	end
	VORPcore.NotifyRightTip(_U("doorNotShow"), 4000)

	local type2 = false
	while true do
		Wait(5)
		local id = PlayerId()
		if not type2 then
			if IsControlJustReleased(0, 0xCEFD9220) then type2 = true end
			if IsPlayerFreeAiming(id) then
				local bool, entity = GetEntityPlayerIsFreeAimingAt(id)
				if bool then
					local model = GetEntityModel(entity)
					if model ~= nil and model ~= 0 then
						devPrint("Model found: " .. model)
						for k, v in pairs(Doorhashes) do
							if v[2] == model then
								table.insert(modelAimedAt, v)
							end
						end

						for k, v in pairs(modelAimedAt) do
							local aimedEntityCoords = GetEntityCoords(entity)
							if GetDistanceBetweenCoords(v[4], v[5], v[6], aimedEntityCoords.x, aimedEntityCoords.y, aimedEntityCoords.z, true) < 1 then
								door = v
								break
							end
						end
						if door ~= nil then
							if type == 'creation' then
								devPrint("Creation prompt for door displayed.")
								BccUtils.Misc.DrawText3D(door[4], door[5], door[6] + 1, _U("questionLocking"))
							elseif type == 'deletion' then
								devPrint("Deletion prompt for door displayed.")
								BccUtils.Misc.DrawText3D(door[4], door[5], door[6] + 1, _U("questionDeletion"))
							end
							if IsControlJustReleased(0, 0x760A9C6F) then break end
						end
					end
				end
			end
		else
			local plc = GetEntityCoords(PlayerPedId())
			for k, v in pairs(Doorhashes) do
				if GetDistanceBetweenCoords(plc.x, plc.y, plc.z, v[4], v[5], v[6], true) < 1.5 then
					door = v
					break
				end
			end
			if door ~= nil then
				if GetDistanceBetweenCoords(plc.x, plc.y, plc.z, door[4], door[5], door[6], true) < 1.5 then
					if type == 'creation' then
						devPrint("Creation prompt displayed for nearby door.")
						BccUtils.Misc.DrawText3D(door[4], door[5], door[6] + 1, _U("questionLocking"))
					elseif type == 'deletion' then
						devPrint("Deletion prompt displayed for nearby door.")
						BccUtils.Misc.DrawText3D(door[4], door[5], door[6] + 1, _U("questionDeletion"))
					end
					if IsControlJustReleased(0, 0x760A9C6F) then break end
				else
					door = nil
				end
			end
		end
	end

	if door ~= nil then
		devPrint("Door found: " .. json.encode(door))
		return door
	end
end

function setDoorLockStatus(doorHash, locked, deletion) -- Function to lock and unlock doors
	devPrint("setDoorLockStatus called with doorHash: " ..
	doorHash .. ", locked: " .. tostring(locked) .. ", deletion: " .. tostring(deletion))
	Citizen.InvokeNative(0xD99229FE93B46286, doorHash, 1, 1, 0, 0, 0, 0)
	local doorstatus = DoorSystemGetDoorState(doorHash)
	if deletion then
		devPrint("Deleting door with doorHash: " .. doorHash)
		Citizen.InvokeNative(0x6BAB9442830C7F53, doorHash, 2)
		Wait(1000)
		Citizen.InvokeNative(0x6BAB9442830C7F53, doorHash, 0)
	else
		if locked then
			if doorstatus ~= 1 then
				devPrint("Locking door.")
				Citizen.InvokeNative(0x6BAB9442830C7F53, doorHash, 1)
				DoorSystemSetOpenRatio(doorHash, 0.0, true)
			end
		else
			if doorstatus ~= 0 then
				devPrint("Unlocking door.")
				Citizen.InvokeNative(0x6BAB9442830C7F53, doorHash, 0)
			end
		end
	end
end

function lockAndUnlockDoorHandler(doorTable) -- Function to lock/unlock doors
	devPrint("lockAndUnlockDoorHandler called with doorTable: " .. json.encode(doorTable))
	local PromptGroup = BccUtils.Prompts:SetupPromptGroup()
	local PromptGroup2 = BccUtils.Prompts:SetupPromptGroup()
	local firstprompt = PromptGroup:RegisterPrompt(_U("lockDoor"), 0x760A9C6F, 1, 1, true, 'hold',
		{ timedeventhash = "MEDIUM_TIMED_EVENT" })
	local firstprompt2 = PromptGroup2:RegisterPrompt(_U("unlockDoor"), 0x760A9C6F, 1, 1, true, 'hold',
		{ timedeventhash = "MEDIUM_TIMED_EVENT" })
	local firstprompt3 = nil
	if Config.LockPicking.allowlockpicking then
		firstprompt3 = PromptGroup2:RegisterPrompt(_U("lockpickDoor"), 0xCEFD9220, 1, 1, true, 'hold',
			{ timedeventhash = "MEDIUM_TIMED_EVENT" })
	end
	local radius = tonumber(Config.DoorRadius)
	while true do
		Wait(5)
		local playerPos = GetEntityCoords(PlayerPedId())
		local doorPos = vector3(doorTable[4], doorTable[5], doorTable[6])
		local dist = #(playerPos - doorPos)
		local doorStatus = DoorSystemGetDoorState(doorTable[1])
		if doorStatus == 2 then break end
		if dist <= radius then
			if doorStatus ~= 1 then
				PromptGroup:ShowGroup(_U("doorManage"))
				if firstprompt:HasCompleted() then
					devPrint("Locking door via prompt.")
					TriggerServerEvent('bcc-doorlocks:ServDoorStatusSet', doorTable, true)
				end
			elseif doorStatus ~= 0 then
				PromptGroup2:ShowGroup(_U("doorManage"))
				if firstprompt2:HasCompleted() then
					devPrint("Unlocking door via prompt.")
					TriggerServerEvent('bcc-doorlocks:ServDoorStatusSet', doorTable, false)
				end
				if Config.LockPicking.allowlockpicking then
					if firstprompt3:HasCompleted() then
						devPrint("Lockpicking door via prompt.")
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
	devPrint("lockpickingMinigame event triggered for doorTable: " .. json.encode(doorTable))
	if Config.LockPicking.bcc_minigames then
		local cfg = {
			focus = true,
			cursor = true,
			maxattempts = Config.LockPicking.minigameSettings.MaxAttemptsPerLock,
			threshold = Config.LockPicking.minigameSettings.difficulty,
			hintdelay = Config.LockPicking.minigameSettings.hintdelay,
			stages = {
				{ deg = 25 },
				{ deg = 0 },
				{ deg = 300 }
			}
		}

		MiniGame.Start('lockpick', cfg, function(result)
			if result.unlocked then
				devPrint("Lockpick succeeded.")
				VORPcore.NotifyRightTip(_U("lockPicked"), 4000)
				TriggerServerEvent('bcc-doorlocks:ServDoorStatusSet', doorTable, false, true)
			else
				devPrint("Lockpick failed.")
				TriggerServerEvent('bcc-doorlocks:RemoveLockpick')
			end
		end)
	elseif Config.LockPicking.rsd_lockpick then
		local stand = 1
		local attempt = 2
		local result = exports.rsd_lockpick:StartLockPick(stand, attempt)
		if result then
			devPrint("RSD lockpick succeeded.")
			VORPcore.NotifyRightTip(_U("lockPicked"), 4000)
			TriggerServerEvent('bcc-doorlocks:ServDoorStatusSet', doorTable, false, true)
		else
			devPrint("RSD lockpick failed.")
			TriggerServerEvent('bcc-doorlocks:RemoveLockpick')
		end
	end
end)

function playKeyAnim() -- Play key animation
	devPrint("Playing key animation.")
	local player = PlayerPedId()
	local plc = GetEntityCoords(player)
	local prop = CreateObject(joaat('P_KEY02X'), plc.x, plc.y, plc.z + 0.2, true, true, true)
	local boneIndex = GetEntityBoneIndexByName(player, "SKEL_R_Finger12")
	RequestAnimDict("script_common@jail_cell@unlock@key")
	while not HasAnimDictLoaded('script_common@jail_cell@unlock@key') do
		Wait(100)
	end
	TaskPlayAnim(player, 'script_common@jail_cell@unlock@key', 'action', 8.0, -8.0, 2500, 31, 0, true, 0, false, 0, false)
	Wait(750)
	AttachEntityToEntity(prop, player, boneIndex, 0.02, 0.0120, -0.00850, 0.024, -160.0, 200.0, true, true, false, true,
		1, true)
	while true do
		Wait(50)
		if not IsEntityPlayingAnim(player, "script_common@jail_cell@unlock@key", "action", 3) then
			DeleteObject(prop)
			ClearPedTasksImmediately(player)
			break
		end
	end
end
