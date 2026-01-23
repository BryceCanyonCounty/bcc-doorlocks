Core = exports.vorp_core:GetCore()
FeatherMenu = exports['feather-menu'].initiate()
BccUtils = exports['bcc-utils'].initiate()
MiniGame = exports['bcc-minigames'].initiate()
DBG = BccUtils.Debug:Get('bcc-doorlocks', Config.devMode.active)

if DBG then
    DBG:Enable()
    DBG:Info('Doorlocks debug initialized')
end

-- Initialize random seed for better math.random usage
math.randomseed(GetGameTimer() + GetRandomIntInRange(1, 1000))
