VORPcore = {}
TriggerEvent("getCore", function(core)
  VORPcore = core
end)
VORPutils = {}
TriggerEvent("getUtils", function(utils)
  VORPutils = utils
end)
BccUtils = exports['bcc-utils'].initiate()
MiniGame = exports['bcc-minigames'].initiate()

function getDoor(type) --Funct to unlock door
  local modelAimedAt, door = {}, nil
  if type == 'creation' then
    VORPcore.NotifyRightTip(_U("createDoorInstructions"), 4000)
  elseif type == 'deletion' then
    VORPcore.NotifyRightTip(_U("deleteDoorInstructions"), 4000)
  end
  while true do
    Wait(5)
    local id = PlayerId()
    if IsPlayerFreeAiming(id) then
      local bool, entity = GetEntityPlayerIsFreeAimingAt(id)
      if bool then
        local model = GetEntityModel(entity)
        if model ~= nil and model ~= 0 then
          for k, v in pairs(Doorhashes) do
            if v[2] == model then
              table.insert(modelAimedAt, v)
            end
          end

          for k, v in pairs(modelAimedAt) do
            local aimedEntityCoords = GetEntityCoords(entity)
            if GetDistanceBetweenCoords(v[4], v[5], v[6], aimedEntityCoords.x, aimedEntityCoords.y, aimedEntityCoords.z, true) < 1 then
              door = v break
            end
          end
          if door ~= nil then
            if type == 'creation' then
              BccUtils.Misc.DrawText3D(door[4], door[5], door[6] + 1, _U("questionLocking"))
            elseif type == 'deletion' then
              BccUtils.Misc.DrawText3D(door[4], door[5], door[6] + 1, _U("questionDeletion"))
            end
            if IsControlJustReleased(0, 0x760A9C6F) then break end
          end
        end
      end
    end
  end

  if door ~= nil then return door end
end

function setDoorLockStatus(doorHash, locked, deletion) --function to lock and unlock doors
  Citizen.InvokeNative(0xD99229FE93B46286,doorHash,1,1,0,0,0,0)
  local doorstatus = DoorSystemGetDoorState(doorHash)
  if deletion then --Using the door state 2 as a way to break the lockandunlock handler loop so if the state is 2 then that loop breaks stopping the loop when the door has been deleted
    Citizen.InvokeNative(0x6BAB9442830C7F53, doorHash, 2)
    Wait(1000)
    Citizen.InvokeNative(0x6BAB9442830C7F53, doorHash, 0)
  else
    if locked then
      if doorstatus ~= 1 then
        Citizen.InvokeNative(0x6BAB9442830C7F53, doorHash, 1)
        DoorSystemSetOpenRatio(doorHash, 0.0, true)
      end
    else
      if doorstatus ~= 0 then
        Citizen.InvokeNative(0x6BAB9442830C7F53, doorHash, 0) -- 1 is locked 0 is unlocked 2 makes door locked, kickable while close but if you walk away and back its unlocked
      end
    end
  end
end

function lockAndUnlockDoorHandler(doorTable) --function to lock doors
  local PromptGroup = VORPutils.Prompts:SetupPromptGroup()
  local PromptGroup2 = VORPutils.Prompts:SetupPromptGroup()
  local firstprompt = PromptGroup:RegisterPrompt(_U("lockDoor"), 0x760A9C6F, 1, 1, true, 'hold', { timedeventhash = "MEDIUM_TIMED_EVENT" })
  local firstprompt2 = PromptGroup2:RegisterPrompt(_U("unlockDoor"), 0x760A9C6F, 1, 1, true, 'hold', { timedeventhash = "MEDIUM_TIMED_EVENT" })
  local firstprompt3 = PromptGroup2:RegisterPrompt(_U("lockpickDoor"), 0xCEFD9220, 1, 1, true, 'hold', { timedeventhash = "MEDIUM_TIMED_EVENT" })
  while true do
    Wait(5)
    local plc = GetEntityCoords(PlayerPedId())
    local dist = GetDistanceBetweenCoords(doorTable[4], doorTable[5], doorTable[6], plc.x, plc.y, plc.z, true)
    local doorStatus = DoorSystemGetDoorState(doorTable[1]) --we use this var to detect if its locked or not since door statuses are synced across clients this will allow us to sync the prompts for locking and unlocking without calling the server again
    if doorStatus == 2 then break end --using this as a way to detect if the door has been deleted and if so break the loop
    if dist < 3 then
      if doorStatus ~= 1 then
        PromptGroup:ShowGroup(_U("doorManage"))
        if firstprompt:HasCompleted() then
          OpenDoor()
          TriggerServerEvent('bcc-doorlocks:ServDoorStatusSet', doorTable, true)
        end
      elseif doorStatus ~= 0 then
        PromptGroup2:ShowGroup(_U("doorManage"))
        if firstprompt2:HasCompleted() then
          OpenDoor()
          TriggerServerEvent('bcc-doorlocks:ServDoorStatusSet', doorTable, false)
        end
        if firstprompt3:HasCompleted() then
          TriggerServerEvent('bcc-doorlocks:LockPickCheck', doorTable)
        end
      end
    elseif dist >= 30 then
      Wait(1500)
    elseif dist >= 100 then
      Wait(3000)
    end
  end
end

function OpenDoor()
  prop_name = 'P_KEY02X'
  local ped = PlayerPedId()
  local x,y,z = table.unpack(GetEntityCoords(ped, true))
  local prop = CreateObject(GetHashKey(prop_name), x, y, z + 0.2, true, true, true)
  local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_Finger12")
  local key = false
  if not IsEntityPlayingAnim(ped, "script_common@jail_cell@unlock@key", "action", 3) then
      local waiting = 0
      RequestAnimDict("script_common@jail_cell@unlock@key")
      while not HasAnimDictLoaded("script_common@jail_cell@unlock@key") do
          waiting = waiting + 100
          Citizen.Wait(100)
          if waiting > 3000 then
              break
          end
      end
      Wait(100)
      TaskPlayAnim(ped, 'script_common@jail_cell@unlock@key', 'action', 8.0, -8.0, 2500, 31, 0, true, 0, false, 0, false)
      Wait(750)
      AttachEntityToEntity(prop, ped,boneIndex, 0.02, 0.0120, -0.00850, 0.024, -160.0, 200.0, true, true, false, true, 1, true)
      key = true
      while key do
          if IsEntityPlayingAnim(ped, "script_common@jail_cell@unlock@key", "action", 3) then
              Wait(100)
          else
              ClearPedSecondaryTask(ped)
              DeleteObject(prop)
              RemoveAnimDict("script_common@jail_cell@unlock@key")
              key = false
              break
          end
      end
  end
end

RegisterNetEvent('bcc-doorlocks:lockpickingMinigame', function(doorTable)
  local cfg = {
    focus = true, -- Should minigame take nui focus
    cursor = true, -- Should minigame have cursor  (required for lockpick)
    maxattempts = Config.LockPicking.minigameSettings.MaxAttemptsPerLock, -- How many fail attempts are allowed before game over
    threshold = Config.LockPicking.minigameSettings.difficulty, -- +- threshold to the stage degree (bigger number means easier)
    hintdelay = Config.LockPicking.minigameSettings.hintdelay, --milliseconds delay on when the circle will shake to show lockpick is in the right position.
    stages = {
      {
        deg = 25 -- 0-360 degrees
      },
      {
        deg = 0 -- 0-360 degrees
      },
      {
        deg = 300 -- 0-360 degrees
      }
    }
  }

  MiniGame.Start('lockpick', cfg, function(result)
    if result.unlocked then
      local ped = PlayerPedId()
      local anim = "mini_games@story@mud5@cracksafe_look_at_dial@small_r@ped"
      local open = "open"
      RequestAnimDict(anim)
      while not HasAnimDictLoaded(anim) do
          Citizen.Wait(50)
      end
      TaskPlayAnim(ped, anim, open, 8.0, -8.0, -1, 32, 0, false, false, false)
      Citizen.Wait(1250)
      VORPcore.NotifyRightTip(_U("lockPicked"), 4000)
      TriggerServerEvent('bcc-doorlocks:ServDoorStatusSet', doorTable, false)
    else
      TriggerServerEvent('bcc-doorlocks:RemoveLockpick')
    end
  end)
end)
