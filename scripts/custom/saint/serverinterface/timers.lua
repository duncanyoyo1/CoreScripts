local SaintTicks = require('custom.saint.common.ticks.main')
local Instance = require('custom.saint.serverinterface.instance')
local config = require('custom.saint.serverinterface.config')

SaintTicks.RegisterTick(function()
    Instance:Tick()
end, config.pollInterval)

SaintTicks.RegisterTick(function()
    if not Instance:IsConnected() then
        Instance:Reconnect()
    end
end, config.reconnectInterval)
