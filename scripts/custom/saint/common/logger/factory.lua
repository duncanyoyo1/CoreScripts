-------------------------------------------------------------------------------
--- SaintLogger
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- Logging client to wrap tes3mp logging api.
-------------------------------------------------------------------------------
local classy = require('classy')

---@class Logger
---@overload fun(loggerName: string): Logger
local Logger = classy('Logger')

---@param loggerName string
function Logger:__init(loggerName)
    self.name = loggerName
    self._previousLogLevel = -1
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
    self._previousLogLevel = logLevel
end

---@param message string
function Logger:Append(message)
    tes3mp.LogAppend(self._previousLogLevel, message)
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

---@param message string
function Logger:Error(message)
    self:Log(enumerations.log.ERROR, message)
end

---@class LoggerFactory
---@field CreatedLoggers table<string, Logger>
---@overload fun(): LoggerFactory
local LoggerFactory = classy('LoggerFactory')

function LoggerFactory:__init()
    self.CreatedLoggers = {}
    self.__InternalLogger = Logger("__SaintLogger_Internal_Logger__") ---@type Logger
end

function LoggerFactory:__LogLoggers()
    for loggerName, _ in pairs(self.CreatedLoggers) do
        self.__InternalLogger:Info(loggerName)
    end
end

---@param name string
---@return Logger
function LoggerFactory:CreateLogger(name)
    local logger = Logger(name)
    if self.CreatedLoggers[name] ~= nil then
        self:__LogLoggers()
        error("Logger by the name '" .. name .. "' already exists. Use a different name or delete the other logger.")
    end
    self.CreatedLoggers[name] = logger
    return logger
end

---Get or create a logger for a given name
---@param name string
---@return Logger
function LoggerFactory:GetLogger(name)
    local logger = self.CreatedLoggers[name]
    if (logger == nil) then
        logger = self:CreateLogger(name)
    end
    return logger
end

return LoggerFactory()
