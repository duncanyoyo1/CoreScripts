local SaintLogger = require('custom.saint.common.logger.main')

local SaintTicks = {}

local logger = SaintLogger:CreateLogger('SaintTicks')

---@class TimerRef
---@field interval number
---@field callback fun()

---@class TimerContainer
---@field timers function[]
---@field timerId number

---@type TimerContainer[]
local Timers = {}

---Creates a 'ticking' function. Does NOT allow params in the callback
---@param callback fun()
---@param tickInterval number
---@return TimerRef
SaintTicks.RegisterTick = function(callback, tickInterval)
    logger:Verbose('Registering a tick')
    local ticks = Timers[tickInterval]
    if not ticks then
        ticks = {}
        Timers[tickInterval] = ticks
        ticks.timers = {}
        ticks.timerId = tes3mp.CreateTimerEx("GlobalSaintTick", tickInterval, "i", tickInterval)
        logger:Verbose('Tick registered and created, starting timer')
        tes3mp.StartTimer(ticks.timerId)
    end
    table.insert(ticks.timers, callback)
    return {
        interval = tickInterval,
        callback = callback,
    }
end

---Remove a ticking function from system
---@param timerRef TimerRef
SaintTicks.RemoveTick = function(timerRef)
    local ticks = Timers[timerRef.interval]
    if not ticks then
        logger:Error('Attempted to access and then remove a tick that likely doesn\'t exist!')
        return
    end

    for index, value in ipairs(ticks) do
        if value == timerRef.callback then
            table.remove(ticks, index)
            return
        end
    end

    logger:Error('Attempted to remove a tick that doesn\'t exist!')
end

---@param tickInterval number
function GlobalSaintTick(tickInterval)
    logger:Verbose('Ticking for ' .. tickInterval .. '...')
    local ticks = Timers[tickInterval]
    for _, callback in pairs(ticks.timers) do
        callback()
    end
    tes3mp.RestartTimer(ticks.timerId, tickInterval)
end

return SaintTicks
