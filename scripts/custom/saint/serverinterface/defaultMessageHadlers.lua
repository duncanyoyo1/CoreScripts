local SaintLogger = require('custom.saint.common.logger.main')
local Instance    = require('custom.saint.serverinterface.instance')

local logger      = SaintLogger:GetLogger('SaintServerMessenger')

Instance:RegisterHandler('WELCOME', function(data)
    logger:Info('Received WELCOME message from server')
    logger:Info('It contained: ' .. data.message)
end)
