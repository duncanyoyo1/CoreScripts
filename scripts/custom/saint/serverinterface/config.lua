local time = require('time')

local serverAddress = 'localhost:4550'
local pollInterval = time.seconds(1/20)
local reconnectInterval = time.seconds(10)
local bootstrap = false
local installNodeDepencencies = false

return {
    serverAddress = serverAddress,
    pollInterval = pollInterval,
    reconnectInterval = reconnectInterval,
    bootstrap = bootstrap,
    installNodeDepencencies = installNodeDepencencies,
}
