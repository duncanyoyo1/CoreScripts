local config          = require('custom.saint.serverinterface.config')
local SocketMessenger = require('custom.saint.serverinterface.messenger')

---@type SocketMessenger
local SM              = SocketMessenger(config.serverAddress)
return SM
