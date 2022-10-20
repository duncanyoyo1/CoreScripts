local customEventHooks = require('customEventHooks')
local Instance = require('custom.saint.serverinterface.instance')

customEventHooks.registerHandler('OnServerPostInit', function()
    Instance:Connect()
end)
