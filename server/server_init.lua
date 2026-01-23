Core = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()
DBG = BccUtils.Debug:Get('bcc-doorlocks', Config.devMode.active)

if DBG then
    DBG:Enable()
    DBG:Info('Doorlocks debug initialized')
end
