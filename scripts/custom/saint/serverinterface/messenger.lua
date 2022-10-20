local pollnet = require('pollnet')
local cjson = require('cjson')
local classy = require('classy')

local SaintLogger = require('custom.saint.common.logger.main')

local logger = SaintLogger:GetLogger('SaintServerMessenger')

local Delimiter = '^'

---@class SocketMessenger
---@overload fun(address: string): SocketMessenger
local SocketMessenger = classy('SocketMessenger')

---@param address string
function SocketMessenger:__init(address)
    self.address = address
    self.handlers = {}
end

function SocketMessenger:Tick()
    if not self.socket then return end

    local ok, msg = self.socket:poll()

    if not ok then
        logger:Error('Connection to webserver lost!')
        self.socket:close()
        self.socket = nil
    end

    if msg then
        local msgType, data = self:ParseMessage(msg)
        if not msgType or not data then
            logger:Warn('Got message and didnt know how to parse: ' .. msg)
            return
        end
        local handlers = self.handlers[msgType:lower()]
        if not handlers then
            logger:Warn('No handlers for message type: ' .. msgType)
            return
        end
        for _, handler in pairs(handlers) do
            handler(data)
        end
    end
end

---@param key string
---@param data table|string
function SocketMessenger:SendMessage(key, data)
    local encodedData = cjson.encode(data)
    local constructedMessage = key .. Delimiter .. encodedData .. Delimiter
    self.socket:send(constructedMessage)
end

---@param datum string
function SocketMessenger:ParseMessage(datum)
    local i, j = string.find(datum, '%^')
    if not i or not j then
        return nil, nil
    end
    return string.sub(datum, 1, i - 1), string.sub(datum, j + 1, #datum)
end

---@param key string The key is trimmed and lowered
---@param handler fun(data: any)
function SocketMessenger:RegisterHandler(key, handler)
    local cleanedKey = key:trim():lower()
    local handlers = self.handlers[cleanedKey]
    if not handlers then
        handlers = {}
        self.handlers[cleanedKey] = handlers
    end
    handlers[#handlers] = handler
end

function SocketMessenger:Close()
    self.socket:close()
    self.socket = nil
    self.handlers = {}
end

function SocketMessenger:IsConnected()
    return self.socket ~= nil
end

function SocketMessenger:Connect()
    self.socket = pollnet.open_tcp(self.address)
end

function SocketMessenger:Reconnect()
    self:Connect()
end

return SocketMessenger
