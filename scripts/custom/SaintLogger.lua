---@class Logger
local Logger = {
    name = '',
    previousLogLevel = -1
}

---@param loggerName string
---@return Logger
function Logger:new(o, loggerName)
    o = o or {}
    setmetatable(o, Logger)
    o.name = loggerName
    return o
end

---@param enumValue number
---@return string
function GetEnumerationToString(enumValue)
    for key, value in pairs(enumerations.log) do
        if enumValue == value then
            return key
        end
    end
    return 'UNKNOWN'
end

---@param logLevel number log level
---@param message string Will be concatted to a string
function Logger:Log(logLevel, message)
    tes3mp.LogMessage(
        logLevel,
        string.format("[%s - %s] %s", self.name, GetEnumerationToString(logLevel), message)
    )
    self.previousLogLevel = logLevel
end

---@param message string
function Logger:Append(message)
    tes3mp.LogAppend(self.previousLogLevel, message)
end

---@param message string
function Logger:Verbose(message)
    self:Log(enumerations.log.VERBOSE, message)
end

---@param message string
function Logger:Info(message)
    self:Log(enumerations.log.INFO, message)
end

---@param message string
function Logger:Warn(message)
    self:Log(enumerations.log.WARN, message)
end

---@class LoggerFactory
---@field CreatedLoggers table<string, Logger>
local LoggerFactory = {
    __InternalLogger = Logger:new(nil, "__SaintLogger_Internal_Logger__"),
    CreatedLoggers = {}
}

---@return LoggerFactory
function LoggerFactory:new(o)
    o = o or {}
    setmetatable(o, LoggerFactory)
    return o
end

function LoggerFactory:__LogLoggers()
    for loggerName, _ in pairs(self.CreatedLoggers) do
        LoggerFactory.__InternalLogger:Info(loggerName)
    end
end

---@param name string
---@return Logger logger
function LoggerFactory:CreateLogger(name)
    local logger = Logger:new(nil, name)
    if self.CreatedLoggers[name] ~= nil then
        self:__LogLoggers()
        error("Logger by the name '" .. name .. "' already exists. Use a different name or delete the other logger.")
    end
    self.CreatedLoggers[name] = logger
    return logger
end

return LoggerFactory:new()
