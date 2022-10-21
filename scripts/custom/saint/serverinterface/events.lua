local customEventHooks = require('customEventHooks')
local config = require('custom.saint.serverinterface.config')
local Boostrap = require('custom.saint.serverinterface.bootstrap')
local InstallDepencencies = require('custom.saint.serverinterface.installNodeDeps')
local Instance = require('custom.saint.serverinterface.instance')

customEventHooks.registerHandler('OnServerPostInit', function()
    if config.installNodeDepencencies then
        InstallDepencencies()
    end
    if config.bootstrap then
        Boostrap()
    end
    Instance:Connect()
    Instance:SendMessage('GREETING', { message = '<3' })
end)
