local customEventHooks = require('customEventHooks')

customEventHooks.registerHandler('OnServerPostInit', function()
    local pathToRoot = tes3mp.GetDataPath() .. '\\..'
    local pathToServer = pathToRoot .. '\\server\\'
    local command =  'npm start --prefix ' .. pathToServer .. ' -- &'
    print('Executing: ' .. command)
    os.execute(command)
    os.execute('$!')
    print('PID is above')
end)
