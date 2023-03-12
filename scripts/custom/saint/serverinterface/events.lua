local customEventHooks    = require('customEventHooks')
local config              = require('custom.saint.serverinterface.config')
local Boostrap            = require('custom.saint.serverinterface.bootstrap')
local InstallDepencencies = require('custom.saint.serverinterface.installNodeDeps')
local Instance            = require('custom.saint.serverinterface.instance')
local SaintLogger         = require('custom.saint.common.logger.main')

local logger              = SaintLogger:GetLogger('SaintServerMessenger')

customEventHooks.registerHandler('OnServerPostInit', function(e)
    logger:Info('Starting server listener...')
    if config.installNodeDepencencies then
        InstallDepencencies()
    end
    if config.bootstrap then
        Boostrap()
    end
    Instance:Connect()
    Instance:SendMessage('GREETING', { message = '<3' })
    return e
end)
