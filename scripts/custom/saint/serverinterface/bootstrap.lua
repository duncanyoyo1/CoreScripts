local customEventHooks = require('customEventHooks')
local SaintLogger = require('custom.saint.common.logger.main')

local logger = SaintLogger:GetLogger('SaintServerMessenger')

customEventHooks.registerHandler('OnServerPostInit', function()
    local pathToRoot = tes3mp.GetDataPath() .. '\\..'
    local pathToServer = '/server'
    local command =  'npm start --prefix ' .. pathToServer .. ' > webserver.log 2>&1 &'
    logger:Info('Executing: ' .. command)
    os.execute(command)
    os.execute('echo $!')
    logger:Info('PID is above (bash pid)')
end)
