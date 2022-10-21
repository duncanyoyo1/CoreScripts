local SaintLogger = require('custom.saint.common.logger.main')
local SaintUtilities = require('custom.saint.common.utilities.main')

local logger = SaintLogger:GetLogger('SaintServerMessenger')

local function InstallDepencencies()
    local start = SaintUtilities.GetCurrentFolder()
    local returnCommand = 'cd ' .. start
    local command = ''
    local goCommand = 'cd '

    if tes3mp.GetOperatingSystemType() == 'Windows' then
        local pathToRoot = tes3mp.GetDataPath() .. '\\..'
        local pathToServer = pathToRoot .. '\\server'

        goCommand = goCommand .. pathToServer
        command = 'npm install > ' .. start .. '\\install-node-deps.log 2>&1' -- .. ' > install-node-deps.log 2>&1'
    else
        local pathToRoot = tes3mp.GetDataPath() .. '/..'
        local pathToServer = pathToRoot .. '/server'
        goCommand = goCommand .. pathToServer
        command = 'npm install > ' .. start .. '/install-node-deps.log 2>&1'
    end

    local bigCommand = goCommand .. ' & ' .. command .. ' & ' .. returnCommand

    logger:Info('Executing: ' .. bigCommand)
    os.execute(bigCommand)
end

return InstallDepencencies
