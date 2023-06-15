VORPcore = {}
TriggerEvent("getCore", function(core)
  VORPcore = core
end)
VORPInv = exports.vorp_inventory:vorp_inventoryApi()
BccUtils = exports['bcc-utils'].initiate()

------ DataBase Handling ------
RegisterServerEvent('bcc-doorlocks:InsertIntoDB', function(doorTable, jobs, keyItem) --Handles door creation and locks the door for all clients upon creation
  local param = { ['jobs'] = json.encode(jobs), ['key'] = keyItem, ['locked'] = 'true', ['doorinfo'] = json.encode(doorTable) }
  local _source = source

  exports.oxmysql:execute("SELECT * FROM doorlocks WHERE doorinfo=@doorinfo", param, function(result)
    if not result[1] then
      exports.oxmysql:execute("INSERT INTO doorlocks ( `jobsallowedtoopen`,`keyitem`,`locked`,`doorinfo` ) VALUES ( @jobs,@key,@locked,@doorinfo )", param)
      TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, true, true, false)
      VORPcore.NotifyRightTip(_source, _U("doorCreated"), 4000)
    else
      VORPcore.NotifyRightTip(_source, _U("doorExists"), 4000)
    end
  end)
end)

RegisterServerEvent('bcc-doorlocks:AdminCheck', function() --admin checking against config settings
  local _source = source
  local character = VORPcore.getUser(_source).getUsedCharacter
  for k, v in pairs(Config.AdminSteamIds) do
    if character.identifier == v.steamid then
      TriggerClientEvent('bcc-doorlocks:AdminVarCatch', _source, true) break
    end
  end
end)

RegisterServerEvent('bcc-doorlocks:InitLoadDoorLocks', function() --this will lock all the doors that are in the db when triggered
  local _source, lockVal = source, nil
  local result = MySQL.query.await("SELECT * FROM doorlocks")
  for k, v in pairs(result) do
    if v.locked == 'true' then
      lockVal = true
    else
      lockVal = false
    end
    local doorTable = json.decode(v.doorinfo)
    TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', _source, doorTable, lockVal, true, false)
  end
end)

RegisterServerEvent('bcc-doorlocks:DeleteDoor', function(doorTable) --Event For Deleting a door
  local param = { ['doorinfo'] = json.encode(doorTable) }
  local _source = source
  exports.oxmysql:execute("DELETE FROM doorlocks WHERE doorinfo=@doorinfo", param)
  TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, false, false, true)
  VORPcore.NotifyRightTip(_source, _U("doorDeleted"), 4000)
end)

RegisterServerEvent('bcc-doorlocks:ServDoorStatusSet', function(doorTable, locked) --used to sync the changing status of doors when a player locks or unlocks a door also checks thier job and for key item required to open it
  local lockedparam = nil
  if locked then
    lockedparam = 'true'
  else
    lockedparam = 'false'
  end
  local param = { ['doorinfo'] = json.encode(doorTable), ['locked'] = lockedparam }
  local _source, jobFound = source, false
  local character = VORPcore.getUser(_source).getUsedCharacter
  local result = MySQL.query.await("SELECT * FROM doorlocks WHERE doorinfo=@doorinfo", param)
  for k, v in pairs(json.decode(result[1].jobsallowedtoopen)) do
    if character.job == v then
      jobFound = true
      exports.oxmysql:execute("UPDATE doorlocks SET locked=@locked WHERE doorinfo=@doorinfo", param)
      TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, locked, true, false)
    end
  end
  if not jobFound then
    if VORPInv.getItemCount(_source, result[1].keyitem) >= 1 then
      exports.oxmysql:execute("UPDATE doorlocks SET locked=@locked WHERE doorinfo=@doorinfo", param)
      TriggerClientEvent('bcc-doorlocks:ClientSetDoorStatus', -1, doorTable, locked, true, false)
    else
      VORPcore.NotifyRightTip(_source, "You don't have the right key", 4000)
    end
  end
end)

RegisterServerEvent('bcc-doorlocks:LockPickCheck', function(doorTable) --Used to check for lockpick before allowing minigame to players
  local _source = source
  if VORPInv.getItemCount(_source, Config.LockPicking.minigameSettings.lockpickitem) >= 1 then
    TriggerClientEvent('bcc-doorlocks:lockpickingMinigame', _source, doorTable)
  else
    VORPcore.NotifyRightTip(_source, _U("noLockpick"), 4000)
  end
end)

RegisterServerEvent('bcc-doorlocks:RemoveLockpick', function() --Removing Lockpick
  local _source = source
  VORPInv.subItem(_source, Config.LockPicking.minigameSettings.lockpickitem, 1)
end)

BccUtils.Versioner.checkRelease(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-doorlocks')
