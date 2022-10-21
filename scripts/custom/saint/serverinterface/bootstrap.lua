local SaintLogger = require('custom.saint.common.logger.main')

local logger = SaintLogger:GetLogger('SaintServerMessenger')

local function Bootstrap()
    local command = ''

    if tes3mp.GetOperatingSystemType() == 'Windows' then
        local pathToRoot = tes3mp.GetDataPath() .. '\\..'
        local pathToServer = pathToRoot .. '\\server'
        command = 'START npm start --prefix ' .. pathToServer
    else
        local pathToRoot = tes3mp.GetDataPath() .. '/..'
        local pathToServer = pathToRoot .. '/server'
        command = 'npm start --prefix ' .. pathToServer .. ' > webserver.log 2>&1 &'

        logger:Warn('SPAWNING SERVER IN BACKGROUND')
        logger:Append('IF THE SERVER EXITS FOR ANY REASON, YOUR WEBSERVER MAY STILL BE RUNNING')
        logger:Append('MAKE SURE TO CLOSE THE WEBSERVER OR DO NOT USE THIS BOOTSTRAP')
        logger:Append('USING KILL COMMANDS (kill, pkill, taskkill, etc)')
    end


    logger:Info('Executing: ' .. command)
    os.execute(command)

    if tes3mp.GetOperatingSystemType() ~= 'Windows' then
        logger:Info('Executing: $!')
        os.execute('$!')
        logger:Warn('The above message should be the webserver PID')
    end
end

return Bootstrap
